#!/usr/bin/env python3
"""
Player Statistics Tracker for AssettoServer
Tracks collisions, playtime, speeds, and other metrics
Posts daily leaderboards to Discord
"""

import re
import json
import time
import requests
from pathlib import Path
from datetime import datetime, timezone, timedelta
from collections import defaultdict

# Configuration
LOG_DIR = Path("/home/acserver/server/logs")
STATS_FILE = Path("/home/acserver/server/player_stats.json")
DISCORD_STATS_WEBHOOK = "https://discord.com/api/webhooks/1427462778075218015/QRjTkpivsX_UgX7NhPP6-i3l4p5gPIMuYTCgqflG0Y5XF-PTpbpm0tZ_WY6lFex8jH3l"  # Chat channel
CHECK_INTERVAL = 1.0
LEADERBOARD_TIME = "23:59"  # Post leaderboard at 11:59 PM

# Stats storage structure
stats = {
    "all_time": {},  # {steam_id: {name, collisions, playtime, max_speed, speeds[], join_count, last_seen}}
    "daily": {},     # Same structure but resets daily
    "last_reset": None
}

# Active sessions
active_sessions = {}  # {steam_id: join_timestamp}
last_position = 0
last_log_file = None
last_leaderboard_post = None

# ============================================================================
# Stats Management
# ============================================================================

def load_stats():
    """Load stats from JSON file"""
    global stats
    if STATS_FILE.exists():
        try:
            with open(STATS_FILE, 'r') as f:
                stats = json.load(f)
            print(f"✓ Loaded stats from {STATS_FILE}")
            
            # Ensure daily stats exist
            if "daily" not in stats:
                stats["daily"] = {}
            if "all_time" not in stats:
                stats["all_time"] = {}
            if "last_reset" not in stats:
                stats["last_reset"] = datetime.now(timezone.utc).isoformat()
                
        except Exception as e:
            print(f"✗ Error loading stats: {e}")
            initialize_stats()
    else:
        initialize_stats()

def initialize_stats():
    """Initialize empty stats structure"""
    global stats
    stats = {
        "all_time": {},
        "daily": {},
        "last_reset": datetime.now(timezone.utc).isoformat()
    }
    save_stats()

def save_stats():
    """Save stats to JSON file"""
    try:
        with open(STATS_FILE, 'w') as f:
            json.dump(stats, f, indent=2)
    except Exception as e:
        print(f"✗ Error saving stats: {e}")

def get_player_stats(steam_id, period="all_time"):
    """Get or create player stats entry"""
    if steam_id not in stats[period]:
        stats[period][steam_id] = {
            "name": "Unknown",
            "collisions": 0,
            "playtime": 0,  # seconds
            "max_speed": 0,
            "speeds": [],  # Store last 100 speeds for average calculation
            "join_count": 0,
            "last_seen": None,
            "checksum_fails": 0,
            "distance_traveled": 0,  # meters (if we can track it)
        }
    return stats[period][steam_id]

def update_player_name(steam_id, name):
    """Update player name in both all-time and daily stats"""
    for period in ["all_time", "daily"]:
        if steam_id in stats[period]:
            stats[period][steam_id]["name"] = name

def record_collision(steam_id, speed=None):
    """Record a collision for a player"""
    for period in ["all_time", "daily"]:
        player = get_player_stats(steam_id, period)
        player["collisions"] += 1
        if speed:
            player["speeds"].append(speed)
            player["speeds"] = player["speeds"][-100:]  # Keep last 100
            if speed > player["max_speed"]:
                player["max_speed"] = speed
    save_stats()

def record_speed(steam_id, speed):
    """Record a speed measurement"""
    for period in ["all_time", "daily"]:
        player = get_player_stats(steam_id, period)
        player["speeds"].append(speed)
        player["speeds"] = player["speeds"][-100:]  # Keep last 100
        if speed > player["max_speed"]:
            player["max_speed"] = speed
    save_stats()

def record_join(steam_id, name):
    """Record player joining"""
    timestamp = time.time()
    active_sessions[steam_id] = timestamp
    
    for period in ["all_time", "daily"]:
        player = get_player_stats(steam_id, period)
        player["name"] = name
        player["join_count"] += 1
        player["last_seen"] = datetime.now(timezone.utc).isoformat()
    
    save_stats()

def record_leave(steam_id):
    """Record player leaving and calculate session time"""
    if steam_id in active_sessions:
        session_time = time.time() - active_sessions[steam_id]
        
        for period in ["all_time", "daily"]:
            player = get_player_stats(steam_id, period)
            player["playtime"] += session_time
            player["last_seen"] = datetime.now(timezone.utc).isoformat()
        
        del active_sessions[steam_id]
        save_stats()

def record_checksum_fail(steam_id, name):
    """Record checksum failure"""
    for period in ["all_time", "daily"]:
        player = get_player_stats(steam_id, period)
        player["name"] = name
        player["checksum_fails"] += 1
        player["last_seen"] = datetime.now(timezone.utc).isoformat()
    save_stats()

def calculate_avg_speed(speeds):
    """Calculate average speed from list"""
    if not speeds:
        return 0
    return sum(speeds) / len(speeds)

def format_time(seconds):
    """Format seconds into readable time"""
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    secs = int(seconds % 60)
    
    if hours > 0:
        return f"{hours}h {minutes}m"
    elif minutes > 0:
        return f"{minutes}m {secs}s"
    else:
        return f"{secs}s"

# ============================================================================
# Log Parsing
# ============================================================================

def get_latest_log():
    """Get the latest log file"""
    log_files = sorted(LOG_DIR.glob("log-*.txt"))
    return log_files[-1] if log_files else None

def parse_steam_id(text):
    """Extract Steam ID from log text"""
    match = re.search(r'(\d{17})', text)
    return match.group(1) if match else None

def parse_speed(text):
    """Extract speed from collision log (if available)"""
    # Example: "Impact speed: 123 km/h"
    match = re.search(r'(\d+)\s*km/h', text)
    if match:
        return int(match.group(1))
    return None

def process_line(line):
    """Process a single log line and update stats"""
    
    # Player connection
    # Example: [INF] il (76561199185532445, 26 (ferrari_f40_s3-02_black/ADAn)) has connected
    match = re.search(r'\[INF\]\s+([\w\s\-_]+?)\s+\((\d{17}),.*?\)\s+has connected', line)
    if match:
        name = match.group(1).strip()
        steam_id = match.group(2)
        record_join(steam_id, name)
        print(f"📊 Join: {name} ({steam_id})")
        return
    
    # Player disconnection - need to track by name and lookup steam_id from active sessions or previous data
    # Example: [INF] il has disconnected
    match = re.search(r'\[INF\]\s+([\w\s\-_]+?)\s+has disconnected', line)
    if match:
        name = match.group(1).strip()
        # Find steam_id from active_sessions or stats by name
        steam_id = None
        for sid, timestamp in list(active_sessions.items()):
            if sid in stats.get("daily", {}) and stats["daily"][sid].get("name") == name:
                steam_id = sid
                break
        if not steam_id:
            for sid, data in stats.get("daily", {}).items():
                if data.get("name") == name:
                    steam_id = sid
                    break
        
        if steam_id:
            record_leave(steam_id)
            print(f"📊 Leave: {name} ({steam_id})")
        else:
            print(f"⚠️ Leave: {name} (Steam ID not found)")
        return
    
    # Collision
    # Example: [INF] Collision: PlayerName (76561198XXXXXXXXX) at 89 km/h
    match = re.search(r'\[INF\].*?[Cc]ollision.*?([\w\s\-_]+?)\s*\((\d{17})\)', line)
    if match:
        name = match.group(1).strip()
        steam_id = match.group(2)
        speed = parse_speed(line)
        record_collision(steam_id, speed)
        print(f"📊 Collision: {name} ({steam_id}) @ {speed} km/h" if speed else f"📊 Collision: {name}")
        return
    
    # Checksum failure
    match = re.search(r'\[INF\].*?[Cc]hecksum.*?fail.*?([\w\s\-_]+?).*?(\d{17})', line)
    if not match:
        match = re.search(r'\[INF\].*?(\d{17}).*?([\w\s\-_]+?).*?checksum.*?fail', line, re.IGNORECASE)
    if match:
        if match.group(1).isdigit() and len(match.group(1)) == 17:
            steam_id = match.group(1)
            name = match.group(2).strip()
        else:
            name = match.group(1).strip()
            steam_id = match.group(2)
        record_checksum_fail(steam_id, name)
        print(f"📊 Checksum fail: {name} ({steam_id})")
        return

def monitor_logs():
    """Monitor log files for new entries"""
    global last_position, last_log_file
    
    log_file = get_latest_log()
    if not log_file:
        return
    
    # Check if log file rotated
    if last_log_file != log_file:
        print(f"📊 Monitoring new log: {log_file}")
        last_log_file = log_file
        last_position = log_file.stat().st_size  # Start from end
    
    try:
        with open(log_file, 'r', encoding='utf-8', errors='ignore') as f:
            f.seek(last_position)
            new_lines = f.readlines()
            last_position = f.tell()
            
            for line in new_lines:
                process_line(line.strip())
    
    except Exception as e:
        print(f"✗ Error monitoring logs: {e}")

# ============================================================================
# Leaderboard Generation
# ============================================================================

def generate_leaderboard():
    """Generate daily leaderboard embed"""
    daily_stats = stats["daily"]
    
    if not daily_stats:
        return None
    
    # Sort by different categories
    by_playtime = sorted(daily_stats.items(), key=lambda x: x[1].get("playtime", 0), reverse=True)[:10]
    by_collisions = sorted(daily_stats.items(), key=lambda x: x[1].get("collisions", 0), reverse=True)[:10]
    by_max_speed = sorted(daily_stats.items(), key=lambda x: x[1].get("max_speed", 0), reverse=True)[:10]
    
    # Calculate cleanest drivers (fewest collisions per hour)
    cleanest = []
    for steam_id, data in daily_stats.items():
        playtime_hours = data.get("playtime", 0) / 3600
        if playtime_hours >= 0.5:  # At least 30 minutes
            collisions_per_hour = data.get("collisions", 0) / playtime_hours if playtime_hours > 0 else 999
            avg_speed = calculate_avg_speed(data.get("speeds", []))
            cleanest.append((steam_id, data, collisions_per_hour, avg_speed))
    cleanest = sorted(cleanest, key=lambda x: x[2])[:10]
    
    # Most aggressive (most collisions per hour)
    aggressive = sorted(cleanest, key=lambda x: x[2], reverse=True)[:5]
    
    # Build embed
    embed = {
        "title": "🏆 Daily Leaderboard - RedLine Souls",
        "description": f"Statistics for {datetime.now(timezone.utc).strftime('%B %d, %Y')}",
        "color": 0xFF4500,  # RedLine orange
        "fields": [],
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "footer": {
            "text": "Stats reset at midnight UTC"
        }
    }
    
    # Most Active (playtime)
    if by_playtime:
        field_value = ""
        for i, (steam_id, data) in enumerate(by_playtime, 1):
            name = data.get("name", "Unknown")
            playtime = format_time(data.get("playtime", 0))
            field_value += f"**{i}.** {name} - {playtime}\n"
        embed["fields"].append({
            "name": "⏱️ Most Active Drivers",
            "value": field_value or "No data",
            "inline": False
        })
    
    # Speed Demons (max speed)
    if by_max_speed:
        field_value = ""
        for i, (steam_id, data) in enumerate(by_max_speed, 1):
            name = data.get("name", "Unknown")
            max_speed = data.get("max_speed", 0)
            avg_speed = calculate_avg_speed(data.get("speeds", []))
            field_value += f"**{i}.** {name} - {max_speed:.0f} km/h (avg: {avg_speed:.0f})\n"
        embed["fields"].append({
            "name": "🚀 Speed Demons",
            "value": field_value or "No data",
            "inline": False
        })
    
    # Cleanest Drivers (fewest collisions per hour)
    if cleanest:
        field_value = ""
        for i, (steam_id, data, cph, avg_speed) in enumerate(cleanest, 1):
            name = data.get("name", "Unknown")
            playtime = format_time(data.get("playtime", 0))
            field_value += f"**{i}.** {name} - {cph:.1f} crashes/hr ({playtime})\n"
        embed["fields"].append({
            "name": "🧼 Cleanest Drivers",
            "value": field_value or "No data",
            "inline": False
        })
    
    # Most Crashes
    if by_collisions:
        field_value = ""
        for i, (steam_id, data) in enumerate(by_collisions[:5], 1):
            name = data.get("name", "Unknown")
            collisions = data.get("collisions", 0)
            field_value += f"**{i}.** {name} - {collisions} collisions\n"
        embed["fields"].append({
            "name": "💥 Most Crashes",
            "value": field_value or "No data",
            "inline": False
        })
    
    # Fun stats
    total_collisions = sum(d.get("collisions", 0) for d in daily_stats.values())
    total_playtime = sum(d.get("playtime", 0) for d in daily_stats.values())
    unique_players = len(daily_stats)
    
    fun_stats = f"**Total Players:** {unique_players}\n"
    fun_stats += f"**Total Crashes:** {total_collisions}\n"
    fun_stats += f"**Total Playtime:** {format_time(total_playtime)}\n"
    
    if by_max_speed:
        fastest = by_max_speed[0][1]
        fun_stats += f"**Fastest Speed:** {fastest.get('max_speed', 0):.0f} km/h by {fastest.get('name', 'Unknown')}\n"
    
    embed["fields"].append({
        "name": "📊 Server Stats",
        "value": fun_stats,
        "inline": False
    })
    
    return embed

def post_leaderboard():
    """Post leaderboard to Discord"""
    embed = generate_leaderboard()
    
    if not embed:
        print("📊 No stats to post")
        return
    
    try:
        response = requests.post(DISCORD_STATS_WEBHOOK, json={"embeds": [embed]}, timeout=10)
        if response.status_code in [200, 204]:
            print("✓ Leaderboard posted to Discord")
            reset_daily_stats()
        else:
            print(f"✗ Discord error: {response.status_code}")
    except Exception as e:
        print(f"✗ Error posting leaderboard: {e}")

def reset_daily_stats():
    """Reset daily stats"""
    stats["daily"] = {}
    stats["last_reset"] = datetime.now(timezone.utc).isoformat()
    save_stats()
    print("📊 Daily stats reset")

def check_leaderboard_time():
    """Check if it's time to post leaderboard"""
    global last_leaderboard_post
    
    now = datetime.now(timezone.utc)
    current_time = now.strftime("%H:%M")
    today = now.date()
    
    # Post at LEADERBOARD_TIME once per day
    if current_time == LEADERBOARD_TIME and last_leaderboard_post != today:
        print("📊 Posting daily leaderboard...")
        post_leaderboard()
        last_leaderboard_post = today

# ============================================================================
# Main Loop
# ============================================================================

def main():
    """Main monitoring loop"""
    print("=" * 60)
    print("Player Statistics Tracker")
    print("=" * 60)
    
    load_stats()
    
    print(f"✓ Monitoring logs in: {LOG_DIR}")
    print(f"✓ Stats file: {STATS_FILE}")
    print(f"✓ Daily leaderboard at: {LEADERBOARD_TIME} UTC")
    print("✓ Running...")
    
    while True:
        try:
            monitor_logs()
            check_leaderboard_time()
            time.sleep(CHECK_INTERVAL)
        except KeyboardInterrupt:
            print("\n📊 Shutting down stats tracker...")
            # Save any active sessions
            for steam_id in list(active_sessions.keys()):
                record_leave(steam_id)
            save_stats()
            break
        except Exception as e:
            print(f"✗ Error in main loop: {e}")
            time.sleep(CHECK_INTERVAL)

if __name__ == "__main__":
    main()
