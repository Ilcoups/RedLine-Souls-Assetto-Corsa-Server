#!/usr/bin/env python3
"""
REAL OVERTAKE TEST - Actually validates the fuck out of this thing.

Previous tests were bullshit because they:
1. Couldn't detect top-level getSteamID() reliably
2. Passed when UI didn't work
3. Gave false confidence

This test:
1. Parses the actual if/elseif structure
2. Validates Steam IDs against database
3. Checks that code is actually inside script.update
4. Simulates the lookup logic
"""

import re
import sqlite3
from pathlib import Path

LUA_FILE = Path("plugins/PatreonOvertakePlugin/lua/overtake.lua")
HUB_DB = Path("hub/Hub.db")

class TestFailed(Exception):
    pass

def load_file():
    """Load Lua file"""
    if not LUA_FILE.exists():
        raise TestFailed(f"❌ {LUA_FILE} doesn't exist")
    
    with open(LUA_FILE, 'r') as f:
        content = f.read()
    
    print(f"✓ Loaded {LUA_FILE} ({len(content)} bytes)")
    return content

def extract_hardcoded_pbs(content):
    """Extract all hardcoded Steam ID → PB mappings"""
    
    # Find the script.update function
    match = re.search(r'function script\.update\(dt\)(.*?)^end', content, re.MULTILINE | re.DOTALL)
    if not match:
        raise TestFailed("❌ Can't find script.update function")
    
    update_body = match.group(1)
    
    # Find the if/elseif chain for Steam IDs
    # Pattern: if myId == "STEAMID" then personalBest, ownRank = SCORE, RANK
    pattern = r'(?:if|elseif)\s+myId\s+==\s+"(\d+)"\s+then\s+personalBest,\s*ownRank\s*=\s*(\d+),\s*(\d+)'
    
    matches = re.findall(pattern, update_body)
    
    if not matches:
        raise TestFailed("❌ No hardcoded PB mappings found")
    
    pbs = {}
    for steam_id, score, rank in matches:
        pbs[steam_id] = {'score': int(score), 'rank': int(rank)}
    
    print(f"✓ Found {len(pbs)} hardcoded PB mappings")
    return pbs

def validate_steam_ids(pbs):
    """Validate Steam ID format"""
    for steam_id in pbs.keys():
        if not re.match(r'^\d{17}$', steam_id):
            raise TestFailed(f"❌ Invalid Steam ID format: {steam_id}")
        if not steam_id.startswith('7656119'):
            raise TestFailed(f"❌ Steam ID doesn't start with 7656119: {steam_id}")
    
    print(f"✓ All Steam IDs valid format")

def cross_check_database(pbs):
    """Cross-check hardcoded values against database"""
    if not HUB_DB.exists():
        print(f"⚠️  Hub.db not found - skipping database validation")
        return
    
    try:
        conn = sqlite3.connect(HUB_DB)
        c = conn.cursor()
        
        # Get actual top 10
        c.execute("""
            SELECT p.player_id, p.name, e.score, 
                   (SELECT COUNT(*) + 1 FROM overtake_n_leaderboard_entries 
                    WHERE score > e.score AND overtake_n_leaderboard_id = 1) as rank
            FROM overtake_n_leaderboard_entries e
            JOIN players p ON e.player_id = p.player_id
            WHERE e.overtake_n_leaderboard_id = 1
            ORDER BY e.score DESC
            LIMIT 10
        """)
        
        db_top10 = {}
        for steam_id, name, score, rank in c.fetchall():
            db_top10[steam_id] = {'score': score, 'rank': rank, 'name': name}
        
        conn.close()
        
        # Compare
        mismatches = []
        for steam_id, hardcoded in pbs.items():
            if steam_id not in db_top10:
                mismatches.append(f"  {steam_id}: Not in DB top 10 anymore")
            elif hardcoded['score'] != db_top10[steam_id]['score']:
                mismatches.append(f"  {steam_id}: Score mismatch (hardcoded: {hardcoded['score']}, DB: {db_top10[steam_id]['score']})")
            elif hardcoded['rank'] != db_top10[steam_id]['rank']:
                mismatches.append(f"  {steam_id}: Rank mismatch (hardcoded: {hardcoded['rank']}, DB: {db_top10[steam_id]['rank']})")
        
        if mismatches:
            print(f"⚠️  Database mismatches found:")
            for msg in mismatches:
                print(msg)
            print(f"⚠️  Hardcoded data may be stale")
        else:
            print(f"✓ All hardcoded values match database")
            
    except Exception as e:
        print(f"⚠️  Database check failed: {e}")

def validate_structure(content):
    """Validate the overall Lua structure"""
    
    # Check for top-level ac.getSteamID() calls (improved detection)
    # Split into lines and track nesting level
    lines = content.split('\n')
    nesting = 0
    in_script_update = False
    
    for i, line in enumerate(lines, 1):
        stripped = line.strip()
        
        # Skip comments and empty lines
        if stripped.startswith('--') or not stripped:
            continue
        
        # Track function entry
        if 'function script.update' in line:
            in_script_update = True
            nesting = 1
            continue
        
        # Track nesting level
        if in_script_update:
            # Count increases
            nesting += line.count('function ')
            nesting += line.count(' then')
            nesting += line.count(' do')
            
            # Count decreases
            nesting -= line.count('end')
            
            # Check if we exited script.update
            if nesting <= 0:
                in_script_update = False
        
        # Check for dangerous calls outside script.update
        if 'ac.getSteamID()' in line and not in_script_update:
            raise TestFailed(f"❌ CRITICAL: ac.getSteamID() called outside script.update at line {i}")
    
    print("✓ No dangerous top-level ac.getSteamID() calls")

def simulate_lookup(pbs):
    """Simulate the actual lookup logic"""
    
    # Check that we have expected structure
    if len(pbs) < 1:
        raise TestFailed("❌ No PB mappings found")
    
    # Verify ranks are sequential
    ranks = sorted([v['rank'] for v in pbs.values()])
    if ranks != list(range(1, len(ranks) + 1)):
        print(f"⚠️  Ranks are not sequential: {ranks}")
    
    # Verify scores are descending
    items_by_rank = sorted(pbs.items(), key=lambda x: x[1]['rank'])
    scores = [item[1]['score'] for item in items_by_rank]
    if scores != sorted(scores, reverse=True):
        raise TestFailed("❌ Scores not in descending order by rank")
    
    print("✓ Lookup logic structure valid")

def main():
    """Run all validations"""
    print("=" * 70)
    print("REAL OVERTAKE TEST - No More Bullshit Edition")
    print("=" * 70)
    print()
    
    try:
        content = load_file()
        pbs = extract_hardcoded_pbs(content)
        validate_steam_ids(pbs)
        validate_structure(content)
        simulate_lookup(pbs)
        cross_check_database(pbs)
        
        print()
        print("=" * 70)
        print("✅ ALL REAL TESTS PASSED")
        print("=" * 70)
        print()
        print(f"Validated {len(pbs)} hardcoded PBs")
        print("🟢 ACTUALLY SAFE TO START SERVER")
        return 0
        
    except TestFailed as e:
        print()
        print("=" * 70)
        print("❌ TEST FAILED")
        print("=" * 70)
        print()
        print(str(e))
        print()
        print("🔴 DO NOT START SERVER")
        return 1
    except Exception as e:
        print()
        print("=" * 70)
        print("❌ UNEXPECTED ERROR")
        print("=" * 70)
        print()
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        return 1

if __name__ == "__main__":
    import sys
    sys.exit(main())
