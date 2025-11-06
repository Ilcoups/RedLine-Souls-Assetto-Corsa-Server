#!/usr/bin/env python3
"""Generate live server status JSON"""

import json
import time
from pathlib import Path
from datetime import datetime, timezone

# Read active sessions from unified_announcer state
STATS_FILE = Path("/home/acserver/server/player_stats.json")
OUTPUT_FILE = Path("/home/acserver/server/wwwroot/status.json")

def load_stats():
    if STATS_FILE.exists():
        with open(STATS_FILE, 'r') as f:
            return json.load(f)
    return {"all_time": {}, "daily": {}}

def get_online_players():
    """Parse log for currently connected players"""
    log_file = Path("/home/acserver/server/logs").glob("log-*.txt")
    latest_log = max(log_file, default=None)
    
    if not latest_log:
        return []
    
    connected = {}
    
    with open(latest_log, 'r') as f:
        for line in f:
            if "has connected" in line:
                # Extract: Name (SteamID, CarID (car-skin))
                match = line.split("[INF] ")
                if len(match) > 1:
                    parts = match[1].split(" (")
                    if len(parts) >= 3:
                        name = parts[0].strip()
                        steam_id = parts[1].split(",")[0]
                        car = parts[2].split("-")[0] if "-" in parts[2] else "unknown"
                        connected[steam_id] = {"name": name, "car": car}
            elif "has disconnected" in line:
                match = line.split("[INF] ")
                if len(match) > 1:
                    name = match[1].split(" has")[0].strip()
                    # Remove by name
                    for sid, data in list(connected.items()):
                        if data["name"] == name:
                            del connected[sid]
    
    return list(connected.values())

def generate_status():
    stats = load_stats()
    online = get_online_players()
    
    daily_stats = stats.get("daily", {})
    unique_today = len(daily_stats)
    total_crashes_today = sum(p.get("collisions", 0) for p in daily_stats.values())
    
    status = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "server": {
            "name": "RedLine Souls",
            "status": "online",
            "track": "Shuto Revival Project",
            "max_players": 35
        },
        "online": {
            "count": len(online),
            "players": online
        },
        "today": {
            "unique_players": unique_today,
            "total_crashes": total_crashes_today
        }
    }
    
    OUTPUT_FILE.parent.mkdir(exist_ok=True)
    with open(OUTPUT_FILE, 'w') as f:
        json.dump(status, f, indent=2)
    
    print(f"✓ Status updated: {len(online)} online")

if __name__ == "__main__":
    generate_status()
