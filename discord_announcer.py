#!/usr/bin/env python3
"""
Simple Connection Announcer for AssettoServer
Posts player join/disconnect to Discord webhook
"""

import re
import time
import requests
from pathlib import Path
from datetime import datetime

# Configuration
LOG_DIR = Path("/home/acserver/server/logs")
DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1427443975425364018/8KIkIU-vjxSMEQuMhaiQ3gia-EIFMF48s_98xMTngfthM_A8eW2aDD0M_TjrfOVwJ0ah"
CHECK_INTERVAL = 0.5

# Track last position
last_position = 0
last_log_file = None

def get_current_log_file():
    today = datetime.now().strftime("%Y%m%d")
    return LOG_DIR / f"log-{today}.txt"

def send_discord(message, color=0x00ff00):
    """Send message to Discord"""
    try:
        embed = {
            "embeds": [{
                "description": message,
                "color": color,
                "timestamp": datetime.utcnow().isoformat()
            }]
        }
        response = requests.post(DISCORD_WEBHOOK, json=embed, timeout=5)
        if response.status_code in [200, 204]:
            print(f"✓ Discord: {message}")
        else:
            print(f"✗ Discord failed: HTTP {response.status_code}")
    except Exception as e:
        print(f"✗ Discord error: {e}")

def monitor_logs():
    global last_position, last_log_file
    
    log_file = get_current_log_file()
    
    if log_file != last_log_file:
        last_position = 0
        last_log_file = log_file
        print(f"Monitoring: {log_file}")
    
    if not log_file.exists():
        return
    
    try:
        with open(log_file, 'r', encoding='utf-8') as f:
            f.seek(last_position)
            new_lines = f.readlines()
            last_position = f.tell()
            
            for line in new_lines:
                process_line(line)
    except Exception as e:
        print(f"Error reading log: {e}")

def process_line(line):
    """Process log line for player events"""
    
    # Connection: il (76561199185532445, 26 (ferrari_f40_s3-02_black/ADAn)) has connected
    if " has connected" in line and "[INF]" in line:
        match = re.search(r'\[INF\]\s+(.+?)\s+\((\d+),\s+\d+\s+\((.+?)\)', line)
        if match:
            player_name = match.group(1).strip()
            steam_id = match.group(2)
            car = match.group(3).split('-')[0] if '-' in match.group(3) else match.group(3)
            send_discord(f":green_circle: **{player_name}** joined (Steam: {steam_id}, Car: {car})", 0x00ff00)
    
    # Disconnection: il has disconnected
    elif " has disconnected" in line and "[INF]" in line:
        match = re.search(r'\[INF\]\s+(.+?)\s+has disconnected', line)
        if match:
            player_name = match.group(1).strip()
            send_discord(f":red_circle: **{player_name}** left the server", 0xff0000)
    
    # Checksum failure
    elif "checksum" in line.lower() and ("fail" in line.lower() or "error" in line.lower()):
        match = re.search(r'(\w+).*checksum', line, re.IGNORECASE)
        if match:
            player_name = match.group(1)
            send_discord(f":warning: **{player_name}** failed checksum verification", 0xffaa00)

def main():
    print("=" * 60)
    print("AssettoServer Discord Announcer")
    print("=" * 60)
    print(f"Webhook: {DISCORD_WEBHOOK[:50]}...")
    print(f"Logs: {LOG_DIR}")
    print()
    print("Monitoring for player events...")
    print()
    
    # Send startup message
    send_discord(":white_check_mark: Discord announcer started - monitoring connections", 0x0099ff)
    
    try:
        while True:
            monitor_logs()
            time.sleep(CHECK_INTERVAL)
    except KeyboardInterrupt:
        print("\nShutting down...")
        send_discord(":octagonal_sign: Discord announcer stopped", 0x999999)

if __name__ == "__main__":
    main()
