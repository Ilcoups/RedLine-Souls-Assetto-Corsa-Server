#!/usr/bin/env python3
"""Auto-regenerate overtake PB data for Lua script from Hub database.

This script should run via cron every 5 minutes to keep PB data fresh.
It embeds the data directly into overtake.lua to avoid CSP require() issues.
"""

import sqlite3
import shutil
from pathlib import Path
from datetime import datetime

# Paths
SCRIPT_DIR = Path(__file__).parent
HUB_DB = SCRIPT_DIR / "hub" / "Hub.db"
TARGET_FILE = SCRIPT_DIR / "plugins/PatreonOvertakePlugin/lua/overtake.lua"
BACKUP_DIR = SCRIPT_DIR / "cfg/pb_data_backups"
LOG_FILE = SCRIPT_DIR / "logs/pb_data_updates.log"

def log(message):
    """Simple logging"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_msg = f"[{timestamp}] {message}"
    print(log_msg)
    
    LOG_FILE.parent.mkdir(exist_ok=True)
    with open(LOG_FILE, 'a') as f:
        f.write(log_msg + "\n")

def backup_existing():
    """Backup current lua file before overwriting"""
    if TARGET_FILE.exists():
        BACKUP_DIR.mkdir(parents=True, exist_ok=True)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_file = BACKUP_DIR / f"overtake_lua_backup_{timestamp}.lua"
        
        shutil.copy2(TARGET_FILE, backup_file)
        log(f"✓ Backed up to {backup_file.name}")
        
        # Keep only last 10 backups
        backups = sorted(BACKUP_DIR.glob("overtake_lua_backup_*.lua"), key=lambda p: p.stat().st_mtime, reverse=True)
        for old_backup in backups[10:]:
            old_backup.unlink()
            log(f"  Cleaned old backup: {old_backup.name}")

def generate_pb_data():
    """Generate lua file from Hub database"""
    if not HUB_DB.exists():
        log(f"❌ Hub database not found: {HUB_DB}")
        return False
    
    try:
        conn = sqlite3.connect(HUB_DB)
        c = conn.cursor()
        
        # Query all scores from overtake_N table
        c.execute("""
            SELECT p.player_id, p.name, e.score, 
                   (SELECT COUNT(*) + 1 FROM overtake_n_leaderboard_entries 
                    WHERE score > e.score AND overtake_n_leaderboard_id = 1) as rank
            FROM overtake_n_leaderboard_entries e
            JOIN players p ON e.player_id = p.player_id
            WHERE e.overtake_n_leaderboard_id = 1
            ORDER BY e.score DESC
        """)
        
        results = c.fetchall()
        conn.close()
        
        if not results:
            log("⚠️  No overtake entries found in database")
            return False
            
        # Read current file
        with open(TARGET_FILE, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            
        # Generate embedded code block
        embedded_code = []
        embedded_code.append("\n-- ====================================================================\n")
        embedded_code.append(f"-- AUTO-GENERATED PB DATABASE - {len(results)} PLAYERS\n")
        embedded_code.append(f"-- Updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}\n")
        embedded_code.append("-- This section is regenerated every 5 minutes by update_pb_data.py\n")
        embedded_code.append("-- ====================================================================\n")
        embedded_code.append("local KNOWN_PBS = {\n")

        for steam_id, name, score, rank in results:
            safe_name = name.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')
            embedded_code.append(f'  ["{steam_id}"] = {{score = {score}, rank = {rank}, name = "{safe_name}"}},\n')

        embedded_code.append("}\n")
        embedded_code.append("-- ====================================================================\n\n")
        
        # Replace existing block or insert new
        new_lines = []
        skip = False
        found_block = False
        
        for line in lines:
            if "AUTO-GENERATED PB DATABASE" in line:
                skip = True
                found_block = True
            elif skip and "====================================================================" in line and "AUTO-GENERATED" not in lines[lines.index(line)-1]:
                skip = False
                continue
            
            if not skip:
                new_lines.append(line)
        
        # Find insertion point (before update function)
        insert_point = 0
        for i, line in enumerate(new_lines):
            if 'function script.update(dt)' in line:
                insert_point = i
                break
        
        if insert_point == 0:
            log("❌ Could not find insertion point in overtake.lua")
            return False
            
        # Insert new block
        final_lines = new_lines[:insert_point] + embedded_code + new_lines[insert_point:]
        
        # Write back to file
        with open(TARGET_FILE, 'w', encoding='utf-8') as f:
            f.writelines(final_lines)
        
        log(f"✓ Embedded {len(results)} players into {TARGET_FILE.name}")
        return True
        
    except Exception as e:
        log(f"❌ Error generating PB data: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """Main update process"""
    log("=" * 60)
    log("Starting PB data update (Embedded Strategy)")
    
    # Backup existing file
    backup_existing()
    
    # Generate new file
    success = generate_pb_data()
    
    if success:
        log("✅ PB data update completed successfully")
    else:
        log("❌ PB data update failed")
        return 1
    
    log("=" * 60)
    return 0

if __name__ == "__main__":
    exit(main())
