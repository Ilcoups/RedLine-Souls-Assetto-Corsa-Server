#!/usr/bin/env python3
"""
Player Statistics Tracker for AssettoServer
Tracks collisions, playtime, speeds, and other metrics
Posts daily leaderboards to Discord
"""

import re
import json
import time
import random
import requests
import os
from pathlib import Path
from datetime import datetime, timezone, timedelta
from collections import defaultdict

# Load environment variables from .env file
ROOT_DIR = Path(__file__).resolve().parent
env_path = ROOT_DIR / '.env'
if env_path.exists():
    try:
        with open(env_path, 'r', encoding='utf-8') as f:
            for raw in f:
                line = raw.strip()
                if not line or line.startswith('#'):
                    continue
                if '=' in line:
                    k, v = line.split('=', 1)
                    k = k.strip()
                    v = v.strip().strip('"\'')
                    if k and v:
                        os.environ.setdefault(k, v)
        print("✓ Loaded environment variables from .env")
    except Exception as e:
        print(f"⚠ Warning: Could not load .env file: {e}")
else:
    print("⚠ Warning: .env file not found, using environment variables only")

# Configuration
# Configuration
LOG_DIR = ROOT_DIR / "logs"
STATS_FILE = ROOT_DIR / "player_stats.json"
DISCORD_STATS_WEBHOOK = os.getenv('DISCORD_STATS_WEBHOOK')
CHECK_INTERVAL = 1.0
LEADERBOARD_TIME = "23:59"  # Post leaderboard at 11:59 PM

# Validate critical configuration
if not DISCORD_STATS_WEBHOOK:
    print("⚠ WARNING: DISCORD_STATS_WEBHOOK not set! Daily leaderboards will NOT be posted.")
    print("   Set DISCORD_STATS_WEBHOOK in .env file to enable statistics posting.")
else:
    print(f"✓ Discord stats webhook configured")

print(f"✓ Player Stats Configuration:")
print(f"  - Stats file: {STATS_FILE}")
print(f"  - Log directory: {LOG_DIR}")
print(f"  - Leaderboard time: {LEADERBOARD_TIME}")
print(f"  - Discord posting: {'Enabled' if DISCORD_STATS_WEBHOOK else 'DISABLED'}")

# Stats storage structure
stats = {
    "all_time": {},  # {steam_id: {name, collisions, playtime, max_speed, speeds[], join_count, last_seen}}
    "daily": {},     # Same structure but resets daily
    "last_reset": None,
    "last_leaderboard_post": None,  # Track when we last posted to avoid duplicates
    "last_connection_post": None,  # Track connection stats post
    "daily_meta": {  # Daily server metadata
        "total_connections": 0,
        "peak_concurrent": 0,
        "peak_concurrent_time": None,
        "new_players": set(),  # Steam IDs of first-time joiners
        "checksum_failures": 0
    }
}

# Active sessions
active_sessions = {}  # {steam_id: join_timestamp}
last_position = 0
last_log_file = None
last_leaderboard_post = None
last_connection_post = None

# ============================================================================
# Stats Management
# ============================================================================

def load_stats():
    """Load stats from JSON file"""
    global stats, last_leaderboard_post, last_connection_post
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
            if "last_leaderboard_post" not in stats:
                stats["last_leaderboard_post"] = None
            if "last_connection_post" not in stats:
                stats["last_connection_post"] = None
            if "daily_meta" not in stats:
                stats["daily_meta"] = {
                    "total_connections": 0,
                    "peak_concurrent": 0,
                    "peak_concurrent_time": None,
                    "new_players": [],
                    "checksum_failures": 0
                }
            
            # Convert new_players from list to set
            if isinstance(stats["daily_meta"].get("new_players"), list):
                stats["daily_meta"]["new_players"] = set(stats["daily_meta"]["new_players"])
            
            # Load last leaderboard post date
            if stats.get("last_leaderboard_post"):
                try:
                    last_leaderboard_post = datetime.fromisoformat(stats["last_leaderboard_post"]).date()
                    print(f"✓ Last leaderboard posted: {last_leaderboard_post}")
                except:
                    last_leaderboard_post = None
            
            # Load last connection post date
            if stats.get("last_connection_post"):
                try:
                    last_connection_post = datetime.fromisoformat(stats["last_connection_post"]).date()
                    print(f"✓ Last connection stats posted: {last_connection_post}")
                except:
                    last_connection_post = None
                
        except Exception as e:
            print(f"✗ Error loading stats: {e}")
            initialize_stats()
    else:
        initialize_stats()
    return stats

def initialize_stats():
    """Initialize empty stats structure"""
    global stats
    stats = {
        "all_time": {},
        "daily": {},
        "last_reset": datetime.now(timezone.utc).isoformat(),
        "last_leaderboard_post": None,
        "last_connection_post": None,
        "daily_meta": {
            "total_connections": 0,
            "peak_concurrent": 0,
            "peak_concurrent_time": None,
            "new_players": set(),
            "checksum_failures": 0
        }
    }
    save_stats()

def save_stats():
    """Save stats to JSON file"""
    try:
        # Convert set to list for JSON serialization
        stats_copy = stats.copy()
        if "daily_meta" in stats_copy and "new_players" in stats_copy["daily_meta"]:
            stats_copy["daily_meta"] = stats_copy["daily_meta"].copy()
            stats_copy["daily_meta"]["new_players"] = list(stats_copy["daily_meta"]["new_players"])
        
        with open(STATS_FILE, 'w') as f:
            json.dump(stats_copy, f, indent=2)
    except Exception as e:
        print(f"✗ Error saving stats: {e}")

def get_player_stats(steam_id, period="all_time"):
    """Get or create player stats entry"""
    if steam_id not in stats[period]:
        stats[period][steam_id] = {
            "name": "Unknown",
            "collisions": 0,
            "playtime": 0,
            "max_speed": 0,
            "speeds": [],
            "join_count": 0,
            "last_seen": None,
            "streak": 0,
            "last_streak_date": None
        }
    return stats[period][steam_id]  # FIX: Must return the player data!

def update_player_name(steam_id, name):
    """Update player name in both all-time and daily stats"""
    for period in ["all_time", "daily"]:
        if steam_id in stats[period]:
            stats[period][steam_id]["name"] = name

def record_collision(steam_id, speed=None):
    """Record a collision for a player (only significant impacts >= 30 km/h)"""
    # Filter out minor bumps/road surface contact (< 30 km/h)
    if speed is None or speed < 30:
        return
    
    for period in ["all_time", "daily"]:
        player = get_player_stats(steam_id, period)
        player["collisions"] += 1
        # Track max speed from collision data (only source available)
        if speed > player["max_speed"]:
            player["max_speed"] = speed
    save_stats()

def record_speed(steam_id, speed):
    """Record a speed measurement (only if above 30 km/h to filter noise)"""
    if speed < 30:
        return
    for period in ["all_time", "daily"]:
        player = get_player_stats(steam_id, period)
        if speed > player["max_speed"]:
            player["max_speed"] = speed
    save_stats()

def record_join(steam_id, name):
    """Record player joining"""
    timestamp = time.time()
    active_sessions[steam_id] = timestamp
    
    # Check if this is a new player (not in all_time before this join)
    is_new_player = steam_id not in stats["all_time"]
    
    for period in ["all_time", "daily"]:
        player = get_player_stats(steam_id, period)
        player["name"] = name
        player["join_count"] += 1
        player["last_seen"] = datetime.now(timezone.utc).isoformat()
        
        # Update streak (all_time only)
        if period == "all_time":
            today = datetime.now(timezone.utc).date().isoformat()
            last_date = player.get("last_streak_date")
            
            if last_date:
                last = datetime.fromisoformat(last_date).date()
                yesterday = (datetime.now(timezone.utc).date() - timedelta(days=1))
                
                if last == yesterday:
                    player["streak"] += 1
                elif last.isoformat() != today:
                    player["streak"] = 1
            else:
                player["streak"] = 1
                
            player["last_streak_date"] = today
    
    # Update daily metadata
    stats["daily_meta"]["total_connections"] += 1
    if is_new_player:
        stats["daily_meta"]["new_players"].add(steam_id)
    
    # Update peak concurrent players
    current_concurrent = len(active_sessions)
    if current_concurrent > stats["daily_meta"]["peak_concurrent"]:
        stats["daily_meta"]["peak_concurrent"] = current_concurrent
        stats["daily_meta"]["peak_concurrent_time"] = datetime.now(timezone.utc).isoformat()
    
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
    
    # Track daily checksum failures
    stats["daily_meta"]["checksum_failures"] += 1
    save_stats()

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
    # Example: [INF] il (YOUR_STEAM64_ID, 26 (ferrari_f40_s3-02_black/ADAn)) has connected
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
    # Example: [INF] Collision between PlayerName (15) and environment, rel. speed 130km/h
    match = re.search(r'\[INF\]\s+Collision between ([\w\s\-_]+?)\s+\(\d+\) and .+?, rel\. speed (\d+)km/h', line)
    if match:
        name = match.group(1).strip()
        speed = int(match.group(2))
        
        # Find steam_id by name from active sessions or stats
        steam_id = None
        for sid in list(active_sessions.keys()):
            if sid in stats.get("daily", {}) and stats["daily"][sid].get("name") == name:
                steam_id = sid
                break
        if not steam_id:
            for sid, data in stats.get("daily", {}).items():
                if data.get("name") == name:
                    steam_id = sid
                    break
        
        if steam_id:
            record_collision(steam_id, speed)
            print(f"📊 Collision: {name} @ {speed} km/h")
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

def generate_connection_statistics():
    """Generate daily connection statistics embed"""
    daily_stats = stats["daily"]
    meta = stats["daily_meta"]
    
    if not daily_stats and meta["total_connections"] == 0:
        return None
    
    # Calculate statistics
    total_unique = len(daily_stats)
    total_connections = meta["total_connections"]
    peak_concurrent = meta["peak_concurrent"]
    peak_time = meta.get("peak_concurrent_time")
    new_players_count = len(meta.get("new_players", []))
    checksum_fails = meta.get("checksum_failures", 0)
    
    # Calculate total playtime and average session
    total_playtime_sec = sum(p.get("playtime", 0) for p in daily_stats.values())
    avg_session_sec = total_playtime_sec / total_connections if total_connections > 0 else 0
    
    # Find most active player (by sessions)
    most_active = None
    most_sessions = 0
    for steam_id, data in daily_stats.items():
        joins = data.get("join_count", 0)
        if joins > most_sessions:
            most_sessions = joins
            most_active = data.get("name", "Unknown")
    
    # Find longest single session
    longest_session_player = None
    longest_session_time = 0
    for steam_id, data in daily_stats.items():
        playtime = data.get("playtime", 0)
        if playtime > longest_session_time:
            longest_session_time = playtime
            longest_session_player = data.get("name", "Unknown")
    
    # Format peak time
    if peak_time:
        try:
            peak_dt = datetime.fromisoformat(peak_time)
            peak_time_str = peak_dt.strftime("%H:%M UTC")
        except:
            peak_time_str = "Unknown"
    else:
        peak_time_str = "Unknown"
    
    # Format times
    total_hours = int(total_playtime_sec // 3600)
    total_minutes = int((total_playtime_sec % 3600) // 60)
    avg_minutes = int(avg_session_sec // 60)
    longest_hours = int(longest_session_time // 3600)
    longest_minutes = int((longest_session_time % 3600) // 60)
    
    # Build embed
    embed = {
        "title": "📊 SERVER ACTIVITY REPORT - REDLINE SOULS",
        "description": f"**{datetime.now(timezone.utc).strftime('%B %d, %Y')}**\n\nToday's server statistics and connection metrics",
        "color": 0x5865F2,  # Blurple
        "fields": [
            {
                "name": "👥 Player Connections",
                "value": f"**Unique Players:** {total_unique}\n**Total Connections:** {total_connections}\n**New Faces:** {new_players_count} first-timers! 🆕",
                "inline": False
            },
            {
                "name": "📈 Peak Activity",
                "value": f"**{peak_concurrent} players** online simultaneously\n⏰ Peak time: {peak_time_str}",
                "inline": False
            },
            {
                "name": "⏱️ Server Time",
                "value": f"**Total:** {total_hours}h {total_minutes}m of racing\n**Average Session:** {avg_minutes}m per connection",
                "inline": False
            }
        ],
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "footer": {
            "text": "RedLine Souls • Tokyo Highway Statistics"
        }
    }
    
    # Add notable players section if available
    if most_active or longest_session_player:
        notable = ""
        if most_active:
            notable += f"🏎️ **Most Active:** {most_active} ({most_sessions} sessions)\n"
        if longest_session_player:
            notable += f"🌟 **Longest Session:** {longest_session_player} ({longest_hours}h {longest_minutes}m)"
        
        embed["fields"].append({
            "name": "⭐ Notable Players",
            "value": notable,
            "inline": False
        })
    
    # Add checksum failures if any
    if checksum_fails > 0:
        embed["fields"].append({
            "name": "⚠️ Connection Issues",
            "value": f"**{checksum_fails}** checksum failures today\nPlayers had file mismatch issues",
            "inline": False
        })
    
    return embed

def generate_leaderboard():
    """Generate daily leaderboard embed with fun vibes!"""
    daily_stats = stats["daily"]
    
    if not daily_stats:
        return None
    
    # Filter out short sessions (less than 3 minutes = 180 seconds)
    MIN_SESSION_TIME = 180
    filtered_stats = {k: v for k, v in daily_stats.items() if v.get("playtime", 0) >= MIN_SESSION_TIME}
    
    if not filtered_stats:
        return None
    
    # Sort by different categories (using filtered stats)
    by_playtime = sorted(filtered_stats.items(), key=lambda x: x[1].get("playtime", 0), reverse=True)[:10]
    by_collisions = sorted(filtered_stats.items(), key=lambda x: x[1].get("collisions", 0), reverse=True)[:10]
    by_max_speed = sorted(filtered_stats.items(), key=lambda x: x[1].get("max_speed", 0), reverse=True)[:10]
    
    # Calculate cleanest drivers (fewest collisions per hour, min 30 minutes playtime)
    cleanest = []
    for steam_id, data in filtered_stats.items():
        playtime_hours = data.get("playtime", 0) / 3600
        if playtime_hours >= 0.5:  # At least 30 minutes
            collisions_per_hour = data.get("collisions", 0) / playtime_hours if playtime_hours > 0 else 999
            cleanest.append((steam_id, data, collisions_per_hour))
    cleanest = sorted(cleanest, key=lambda x: x[2])[:10]
    
    # Fun awards
    total_collisions = sum(d.get("collisions", 0) for d in filtered_stats.values())
    total_playtime = sum(d.get("playtime", 0) for d in filtered_stats.values())
    
    # Build embed with fun vibes!
    intro_messages = [
        "Another day, another set of tire marks on the Shuto! 🏁",
        "The Tokyo expressways remember every touge run and every wall tap! 🌃",
        "RedLine Souls never sleep - here's today's chaos! 💨",
        "From C1 to Daikoku, the engines never stopped screaming! 🔥",
        "24 hours of pure JDM adrenaline - check who ruled the streets! ⚡",
        "Kanjo runners and highway kings - here's who dominated today! 🏎️",
        "From Yokohama to Tokyo Tower, check today's street legends! 🗼"
    ]
    
    import random
    embed = {
        "title": "🏆 DAILY LEADERBOARD - REDLINE SOULS",
        "description": f"{random.choice(intro_messages)}\n\n📅 **{datetime.now(timezone.utc).strftime('%B %d, %Y')}**",
        "color": 0xFF4500,  # RedLine orange
        "fields": [],
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "footer": {
            "text": "Tomorrow's another race - stats reset at midnight UTC ⏰"
        }
    }
    
    # Most Active (playtime) - with medals and streaks
    if by_playtime:
        field_value = ""
        medals = ["🥇", "🥈", "🥉"]
        
        # Check for all-time playtime record
        all_time_best_playtime = 0
        for sid, sdata in stats["all_time"].items():
            daily_time = stats["daily"].get(sid, {}).get("playtime", 0)
            all_time_best_playtime = max(all_time_best_playtime, daily_time)
        
        for i, (steam_id, data) in enumerate(by_playtime, 1):
            name = data.get("name", "Unknown")
            playtime_sec = data.get("playtime", 0)
            playtime = format_time(playtime_sec)
            steam_link = f"[{name}](https://steamcommunity.com/profiles/{steam_id})"
            medal = medals[i-1] if i <= 3 else f"**{i}.**"
            
            # Show streak if > 1
            streak = stats["all_time"].get(steam_id, {}).get("streak", 0)
            streak_display = f" 🔥{streak}" if streak > 1 else ""
            
            # Check if this is a new record
            record_display = ""
            if i == 1 and playtime_sec > 28800:  # > 8 hours
                record_display = " ⭐ **MARATHON KING**"
            
            field_value += f"{medal} {steam_link} - {playtime}{streak_display}{record_display}\n"
        embed["fields"].append({
            "name": "⏱️ STREET LEGENDS - MOST SEAT TIME",
            "value": field_value or "No data",
            "inline": False
        })
    
    # Speed Demons - with fun commentary
    if by_max_speed:
        field_value = ""
        speed_comments = {
            1: "👑 ABSOLUTE MADMAN",
            2: "🔥 ALMOST HAD IT", 
            3: "⚡ TRYING HARD",
            4: "💨 DECENT ATTEMPT",
            5: "🚗 GETTING THERE"
        }
        
        # Get all-time speed record
        all_time_best_speed = max((d.get("max_speed", 0) for d in stats["all_time"].values()), default=0)
        
        for i, (steam_id, data) in enumerate(by_max_speed, 1):
            name = data.get("name", "Unknown")
            max_speed = data.get("max_speed", 0)
            steam_link = f"[{name}](https://steamcommunity.com/profiles/{steam_id})"
            comment = speed_comments.get(i, "")
            
            # Check if this breaks the all-time record
            record_display = ""
            if i == 1 and max_speed >= all_time_best_speed and max_speed > 300:
                record_display = " 🏆 **NEW SERVER RECORD!**"
            elif max_speed > 350:
                record_display = " ⚡ **INSANE**"
            
            field_value += f"**{i}.** {steam_link} - **{max_speed:.0f} km/h** {comment}{record_display}\n"
        embed["fields"].append({
            "name": "💥 SPEED DEMONS - FASTEST IMPACT SPEEDS",
            "value": field_value or "No data",
            "inline": False
        })
    
    # Cleanest Drivers - the rare breed
    if cleanest:
        field_value = ""
        for i, (steam_id, data, cph) in enumerate(cleanest, 1):
            name = data.get("name", "Unknown")
            playtime = format_time(data.get("playtime", 0))
            steam_link = f"[{name}](https://steamcommunity.com/profiles/{steam_id})"
            if cph < 1:
                vibe = "🧘 LITERAL BUDDHA"
            elif cph < 3:
                vibe = "😇 ACTUALLY CLEAN"
            elif cph < 5:
                vibe = "👍 NOT BAD"
            else:
                vibe = "🤷 TRYING"
            field_value += f"**{i}.** {steam_link} - {cph:.1f} crashes/hr {vibe}\n"
        embed["fields"].append({
            "name": "🧼 CLEANEST DRIVERS - UNICORNS EXIST",
            "value": field_value or "No data",
            "inline": False
        })
    
    # Wall Hunters - the entertainers
    if by_collisions:
        field_value = ""
        crash_roasts = {
            1: "🎯 PROFESSIONAL WALL FINDER",
            2: "💀 CRASH TEST DUMMY", 
            3: "🏗️ TOKYO DRIFT WANNABE",
            4: "🚧 BARRIER MAGNET",
            5: "📍 GPS TO EVERY GUARDRAIL"
        }
        
        # Crash of the Day - highest impact
        crash_king = by_collisions[0]
        crash_king_name = crash_king[1].get('name', 'Unknown')
        crash_king_collisions = crash_king[1].get('collisions', 0)
        crash_king_link = f"[{crash_king_name}](https://steamcommunity.com/profiles/{crash_king[0]})"
        
        for i, (steam_id, data) in enumerate(by_collisions[:5], 1):
            name = data.get("name", "Unknown")
            collisions = data.get("collisions", 0)
            steam_link = f"[{name}](https://steamcommunity.com/profiles/{steam_id})"
            roast = crash_roasts.get(i, "💥")
            
            # Highlight crash king
            if i == 1:
                field_value += f"👑 **{steam_link}** - **{collisions} crashes** {roast}\n"
            else:
                field_value += f"**{i}.** {steam_link} - {collisions} crashes {roast}\n"
                
        embed["fields"].append({
            "name": "💥 WALL HUNTERS - HALL OF SHAME",
            "value": field_value or "No data",
            "inline": False
        })
    
    # Server Stats - the numbers
    unique_players = len(filtered_stats)
    total_joins = sum(d.get("join_count", 0) for d in filtered_stats.values())
    
    fun_stats = f"👥 **{unique_players}** racers hit the streets\n"
    fun_stats += f"🔄 **{total_joins}** total sessions\n"
    fun_stats += f"💥 **{total_collisions}** walls kissed\n"
    fun_stats += f"⏱️ **{format_time(total_playtime)}** combined seat time\n"
    
    if by_max_speed:
        fastest = by_max_speed[0]
        fastest_name = fastest[1].get('name', 'Unknown')
        fastest_speed = fastest[1].get('max_speed', 0)
        fastest_link = f"[{fastest_name}](https://steamcommunity.com/profiles/{fastest[0]})"
        fun_stats += f"\n💥 **Hardest impact:** {fastest_speed:.0f} km/h by {fastest_link}\n"
    
    if unique_players > 0:
        avg_crashes = total_collisions / unique_players
        if avg_crashes > 10:
            vibe = "🎪 (absolute circus)"
        elif avg_crashes > 5:
            vibe = "😅 (rough day)"
        elif avg_crashes > 2:
            vibe = "🤙 (normal chaos)"
        else:
            vibe = "😎 (surprisingly chill)"
        fun_stats += f"📊 **Avg crashes/player:** {avg_crashes:.1f} {vibe}\n"
    
    embed["fields"].append({
        "name": "📊 TODAY'S MAYHEM IN NUMBERS",
        "value": fun_stats,
        "inline": False
    })
    
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Traffic Poll Results
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    votes_file = ROOT_DIR / "traffic_votes.json"
    if votes_file.exists():
        try:
            import json
            with open(votes_file, 'r') as f:
                all_votes = json.load(f)
            
            today = datetime.now(timezone.utc).strftime('%Y-%m-%d')
            if today in all_votes and all_votes[today]:
                votes = all_votes[today]
                total_votes = len(votes)
                
                # Calculate average and distribution
                ratings = [v['rating'] for v in votes]
                avg_rating = sum(ratings) / len(ratings)
                
                # Count each rating
                rating_counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
                for rating in ratings:
                    rating_counts[rating] += 1
                
                # Build visual bar chart with emojis
                max_count = max(rating_counts.values()) if rating_counts else 1
                poll_value = f"**Average: {avg_rating:.1f}/5** ⭐ ({total_votes} responses)\n\n"
                
                rating_emojis = {1: "😞", 2: "😐", 3: "🙂", 4: "😊", 5: "🤩"}
                for rating in range(5, 0, -1):  # 5 to 1
                    count = rating_counts[rating]
                    percentage = (count / total_votes * 100) if total_votes > 0 else 0
                    bar_length = int((count / max_count) * 10) if max_count > 0 else 0
                    bar = "█" * bar_length + "░" * (10 - bar_length)
                    emoji = rating_emojis[rating]
                    poll_value += f"{emoji} **{rating}** {bar} `{count}` ({percentage:.0f}%)\n"
                
                embed["fields"].append({
                    "name": "📊 AI TRAFFIC FEEDBACK",
                    "value": poll_value,
                    "inline": False
                })
        except Exception as e:
            print(f"⚠ Could not load poll results: {e}")
    
    # Random motivational footer with Tokyo vibes
    footers = [
        "See you on the Wangan tomorrow! 🌙",
        "Remember: it's not about the crashes, it's about the vibes 💯",
        "GG everyone, same time on the Shuto? 🏁",
        "The expressway awaits... C1 never sleeps 🛣️",
        "Another day, another ¥100,000 in repair costs 💸",
        "Keep it sideways, keep it stylish 🎌",
        "The touge calls... will you answer? 🏔️"
    ]
    embed["footer"]["text"] = f"{random.choice(footers)} • Resets at midnight UTC"
    
    return embed

def post_leaderboard():
    """Post leaderboard to Discord"""
    embed = generate_leaderboard()
    
    if not embed:
        print("📊 No stats to post")
        return
    
    try:
        if not DISCORD_STATS_WEBHOOK:
            print("⚠ Discord stats webhook not configured; skipping leaderboard post")
            return

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
    stats["daily_meta"] = {
        "total_connections": 0,
        "peak_concurrent": 0,
        "peak_concurrent_time": None,
        "new_players": set(),
        "checksum_failures": 0
    }
    stats["last_reset"] = datetime.now(timezone.utc).isoformat()
    stats["last_leaderboard_post"] = datetime.now(timezone.utc).date().isoformat()
    stats["last_connection_post"] = datetime.now(timezone.utc).date().isoformat()
    save_stats()
    print("📊 Daily stats reset")

def post_connection_statistics():
    """Post connection statistics to Discord"""
    embed = generate_connection_statistics()
    
    if not embed:
        print("📊 No connection stats to post")
        return
    
    if not DISCORD_STATS_WEBHOOK:
        print("⚠ No webhook configured for stats posting")
        return
    
    try:
        data = {"embeds": [embed]}
        response = requests.post(DISCORD_STATS_WEBHOOK, json=data, timeout=10)
        if response.status_code in [200, 204]:
            print("✓ Connection statistics posted to Discord")
        else:
            print(f"✗ Discord error: {response.status_code}")
    except Exception as e:
        print(f"✗ Error posting connection stats: {e}")

def check_connection_stats_time():
    """Check if it's time to post connection statistics (23:50 UTC)"""
    global last_connection_post
    
    now = datetime.now(timezone.utc)
    today = now.date()
    
    # Post at 23:50 once per day (with 2-minute window)
    hour = now.hour
    minute = now.minute
    in_window = hour == 23 and 50 <= minute <= 52
    
    if in_window and last_connection_post != today:
        print("📊 Posting connection statistics...")
        post_connection_statistics()
        last_connection_post = today
        stats["last_connection_post"] = today.isoformat()
        save_stats()
        print(f"✓ Connection stats posted and timestamp saved: {today}")

def check_leaderboard_time():
    """Check if it's time to post leaderboard"""
    global last_leaderboard_post
    
    now = datetime.now(timezone.utc)
    current_time = now.strftime("%H:%M")
    today = now.date()
    
    # Post at LEADERBOARD_TIME once per day (with 2-minute window for reliability)
    # Check if we're in the posting window (23:59-00:01)
    hour = now.hour
    minute = now.minute
    in_window = (hour == 23 and minute >= 59) or (hour == 0 and minute <= 1)
    
    if in_window and last_leaderboard_post != today:
        print("📊 Posting daily leaderboard...")
        post_leaderboard()
        last_leaderboard_post = today
        stats["last_leaderboard_post"] = today.isoformat()
        save_stats()
        print(f"✓ Leaderboard posted and timestamp saved: {today}")

# ============================================================================
# Main Loop
# ============================================================================

def main():
    """Main monitoring loop"""
    import argparse
    parser = argparse.ArgumentParser(description="Player Statistics Tracker")
    parser.add_argument('--test-summary-now', action='store_true', help='Immediately post daily summary for testing and exit')
    args = parser.parse_args()

    print("=" * 60)
    print("Player Statistics Tracker")
    print("=" * 60)

    load_stats()

    print(f"✓ Monitoring logs in: {LOG_DIR}")
    print(f"✓ Stats file: {STATS_FILE}")
    print(f"✓ Daily leaderboard at: {LEADERBOARD_TIME} UTC")

    # Prevent repeated test summary posts using a memory flag
    test_summary_flag_file = Path(".test_summary_flag")
    if args.test_summary_now:
        if test_summary_flag_file.exists():
            print("⚠ Test summary already posted in this session. Remove .test_summary_flag to re-run.")
            return
        print("✓ Posting test daily summary...")
        post_leaderboard()
        test_summary_flag_file.write_text("posted")
        print("✓ Test summary posted. Exiting.")
        return

    print("✓ Running...")
    while True:
        try:
            monitor_logs()
            check_connection_stats_time()  # Check for 23:50 UTC posting
            check_leaderboard_time()       # Check for 23:59 UTC posting
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
