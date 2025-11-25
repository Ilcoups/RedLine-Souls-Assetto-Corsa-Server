#!/usr/bin/env python3
"""
Auto-refresh daemon for Overtake PB data.
Updates the Lua file with top 10 players from database every minute.
Safe to run - won't interrupt active players (they only load on join).
"""

import sqlite3
import time
import hashlib
from pathlib import Path
from datetime import datetime

HUB_DB = Path("/home/acserver/server/hub/Hub.db")
LUA_FILE = Path("/home/acserver/server/plugins/PatreonOvertakePlugin/lua/overtake.lua")
LOG_FILE = Path("/home/acserver/server/logs/pb_autoupdate.log")
UPDATE_INTERVAL = 60  # seconds

def log(message):
    """Simple logging"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_msg = f"[{timestamp}] {message}"
    print(log_msg)
    LOG_FILE.parent.mkdir(exist_ok=True)
    with open(LOG_FILE, 'a') as f:
        f.write(log_msg + "\n")

def get_top10_from_db():
    """Fetch top 10 players from database"""
    try:
        conn = sqlite3.connect(HUB_DB)
        c = conn.cursor()
        
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
        
        results = c.fetchall()
        conn.close()
        
        return results
    except Exception as e:
        log(f"❌ Database error: {e}")
        return None

def generate_lua_code(top10):
    """Generate the if/elseif chain for top 10 players"""
    if not top10:
        return None
    
    lines = []
    for i, (steam_id, name, score, rank) in enumerate(top10):
        safe_name = name.replace('\\', '\\\\').replace('"', '\\"')
        
        if i == 0:
            lines.append(f'    if myId == "{steam_id}" then')
        else:
            lines.append(f'    elseif myId == "{steam_id}" then')
        
        lines.append(f'      personalBest, ownRank = {score}, {rank}  -- {safe_name}')
    
    lines.append('    else')
    lines.append('      personalBest, ownRank = 0, 0       -- Not in top 10')
    lines.append('    end')
    
    return '\n'.join(lines)

def update_lua_file(top10):
    """Update the Lua file with new top 10 data"""
    lua_code = generate_lua_code(top10)
    if not lua_code:
        return False
    
    try:
        with open(LUA_FILE, 'r') as f:
            content = f.read()
        
        # Find and replace the hardcoded section
        marker_start = '    -- Hardcoded PBs for top 10 players (auto-updated)'
        
        start_idx = content.find(marker_start)
        if start_idx == -1:
            log("❌ Marker not found in Lua file")
            return False
        
        # Find the closing 'end' statement and the ac.log line after it
        search_from = start_idx
        end_idx = content.find('    end\n    \n    ac.log(string.format("[Overtake] PB initialized:', search_from)
        if end_idx == -1:
            log("❌ End marker not found")
            return False
        
        # Replace the section
        new_content = (
            content[:start_idx] +
            '    -- Hardcoded PBs for top 10 players (auto-updated)\n' +
            lua_code + '\n' +
            content[end_idx + 4:]  # Skip the 'end' we found
        )
        
        # Write back
        with open(LUA_FILE, 'w') as f:
            f.write(new_content)
        
        log(f"✓ Updated Lua file with top 10 players")
        return True
        
    except Exception as e:
        log(f"❌ Error updating Lua file: {e}")
        return False

def get_data_hash(top10):
    """Generate hash of current data for change detection"""
    data_str = ''.join([f"{sid}{score}" for sid, _, score, _ in top10])
    return hashlib.md5(data_str.encode()).hexdigest()

def main():
    """Main daemon loop"""
    log("=" * 60)
    log("PB Auto-Update Daemon Started")
    log(f"Update interval: {UPDATE_INTERVAL}s")
    log(f"Target file: {LUA_FILE}")
    log("=" * 60)
    
    last_hash = None
    
    while True:
        try:
            # Fetch latest top 10
            top10 = get_top10_from_db()
            
            if top10:
                current_hash = get_data_hash(top10)
                
                if current_hash != last_hash:
                    log(f"📊 Data changed - updating Lua file...")
                    if update_lua_file(top10):
                        last_hash = current_hash
                        log(f"✅ Update complete (top player: {top10[0][1]} with {top10[0][2]:,} pts)")
                else:
                    log(f"✓ No changes detected")
            
            time.sleep(UPDATE_INTERVAL)
            
        except KeyboardInterrupt:
            log("Daemon stopped by user")
            break
        except Exception as e:
            log(f"❌ Error in main loop: {e}")
            time.sleep(UPDATE_INTERVAL)

if __name__ == "__main__":
    main()
