#!/usr/bin/env python3
"""
RedLine Souls - Overtake Tracker
Tracks overtakes reported by client-side CSP Lua scripts
Server-side persistence + Discord leaderboard
"""

import json
import socket
import struct
import time
from pathlib import Path
from datetime import datetime, timezone, timedelta

# Config
DATA_FILE = Path("/home/acserver/server/overtake_stats.json")
UDP_LISTEN_PORT = 12002  # Separate from AssettoServer
LEADERBOARD_INTERVAL = 3600  # Post leaderboard every hour
MIN_SPEED_KPH = 80  # Minimum speed to count as overtake

# Load environment for Discord webhook
env_path = Path('/home/acserver/server/.env')
DISCORD_STATS_WEBHOOK = None
if env_path.exists():
    with open(env_path, 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                k, v = line.split('=', 1)
                if k == 'DISCORD_STATS_WEBHOOK':
                    DISCORD_STATS_WEBHOOK = v.strip('"').strip("'")

# Data structure: {steam_id: {name, total_overtakes, best_speed, last_seen}}
stats = {}

def load_stats():
    """Load overtake stats from JSON"""
    global stats
    if DATA_FILE.exists():
        try:
            with open(DATA_FILE, 'r') as f:
                stats = json.load(f)
            print(f"✓ Loaded {len(stats)} player records")
        except Exception as e:
            print(f"✗ Error loading stats: {e}")
            stats = {}
    else:
        stats = {}
        print("✓ Starting fresh stats database")

def save_stats():
    """Save overtake stats to JSON"""
    try:
        with open(DATA_FILE, 'w') as f:
            json.dump(stats, f, indent=2)
    except Exception as e:
        print(f"✗ Error saving stats: {e}")

def process_overtake(steam_id, player_name, speed_kph, overtaken_count=1):
    """Record an overtake event"""
    if speed_kph < MIN_SPEED_KPH:
        return  # Too slow, ignore
    
    if steam_id not in stats:
        stats[steam_id] = {
            "name": player_name,
            "total_overtakes": 0,
            "best_speed": 0,
            "last_seen": datetime.now(timezone.utc).isoformat()
        }
    
    # Update stats
    stats[steam_id]["name"] = player_name  # Update name if changed
    stats[steam_id]["total_overtakes"] += overtaken_count
    stats[steam_id]["best_speed"] = max(stats[steam_id]["best_speed"], speed_kph)
    stats[steam_id]["last_seen"] = datetime.now(timezone.utc).isoformat()
    
    print(f"🏁 {player_name}: +{overtaken_count} overtakes @ {speed_kph:.1f} km/h (total: {stats[steam_id]['total_overtakes']})")
    
    save_stats()

def post_leaderboard():
    """Post top overtakers to Discord"""
    if not DISCORD_STATS_WEBHOOK:
        return
    
    # Sort by total overtakes
    sorted_players = sorted(
        [(sid, data) for sid, data in stats.items()],
        key=lambda x: x[1]["total_overtakes"],
        reverse=True
    )[:10]  # Top 10
    
    if not sorted_players:
        return
    
    # Build Discord embed
    import requests
    
    leaderboard_text = ""
    medals = ["🥇", "🥈", "🥉"]
    
    for idx, (steam_id, data) in enumerate(sorted_players):
        medal = medals[idx] if idx < 3 else f"{idx+1}."
        leaderboard_text += f"{medal} **{data['name']}** - {data['total_overtakes']:,} overtakes (best: {data['best_speed']:.0f} km/h)\n"
    
    embed = {
        "title": "🏎️ RedLine Souls - Overtake Leaderboard",
        "description": leaderboard_text,
        "color": 0xff4500,
        "footer": {"text": f"Minimum speed: {MIN_SPEED_KPH} km/h | Updated every hour"},
        "timestamp": datetime.now(timezone.utc).isoformat()
    }
    
    try:
        response = requests.post(
            DISCORD_STATS_WEBHOOK,
            json={"embeds": [embed]},
            timeout=10
        )
        if response.status_code in [200, 204]:
            print(f"✓ Posted leaderboard to Discord ({len(sorted_players)} players)")
        else:
            print(f"✗ Discord error: {response.status_code}")
    except Exception as e:
        print(f"✗ Discord post failed: {e}")

def udp_server():
    """Listen for UDP overtake reports from clients"""
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(('0.0.0.0', UDP_LISTEN_PORT))
    sock.settimeout(1.0)  # 1s timeout for leaderboard checks
    
    print(f"✓ UDP server listening on port {UDP_LISTEN_PORT}")
    
    last_leaderboard = time.time()
    
    while True:
        try:
            data, addr = sock.recvfrom(1024)
            
            # Parse packet: [steam_id_length][steam_id][player_name_length][player_name][speed_kph][count]
            offset = 0
            
            # Steam ID
            steam_id_len = struct.unpack_from('<I', data, offset)[0]
            offset += 4
            steam_id = data[offset:offset+steam_id_len].decode('utf-8')
            offset += steam_id_len
            
            # Player name
            name_len = struct.unpack_from('<I', data, offset)[0]
            offset += 4
            player_name = data[offset:offset+name_len].decode('utf-8')
            offset += name_len
            
            # Speed & count
            speed_kph = struct.unpack_from('<f', data, offset)[0]
            offset += 4
            count = struct.unpack_from('<I', data, offset)[0] if offset < len(data) else 1
            
            # Process
            process_overtake(steam_id, player_name, speed_kph, count)
            
        except socket.timeout:
            # Check if time to post leaderboard
            if time.time() - last_leaderboard >= LEADERBOARD_INTERVAL:
                post_leaderboard()
                last_leaderboard = time.time()
        except Exception as e:
            print(f"✗ UDP error: {e}")

def main():
    print("=" * 70)
    print("RedLine Souls - Overtake Tracker")
    print("=" * 70)
    print(f"UDP Listen Port: {UDP_LISTEN_PORT}")
    print(f"Minimum Speed: {MIN_SPEED_KPH} km/h")
    print(f"Discord Webhook: {'Configured' if DISCORD_STATS_WEBHOOK else 'DISABLED'}")
    print()
    
    load_stats()
    
    try:
        udp_server()
    except KeyboardInterrupt:
        print("\n⚠ Shutting down...")
        save_stats()

if __name__ == "__main__":
    main()
