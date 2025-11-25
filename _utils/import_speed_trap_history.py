#!/usr/bin/env python3
"""
Import historical speed trap violations from Discord
Fetches past messages from Discord channel and rebuilds stats file
"""
import json
import os
import requests
from pathlib import Path
from datetime import datetime, timedelta

# Configuration
DISCORD_CHANNEL_ID = "1427462778075218015"  # Speed trap channel
DISCORD_BOT_TOKEN = None  # Load from hub config
STATS_FILE = Path("/home/acserver/server/_utils/speed_trap_stats.json")
HUB_CONFIG = Path("/home/acserver/server/hub/configuration.yml")

# Load Discord bot token
with open(HUB_CONFIG, 'r') as f:
    for line in f:
        if 'BotToken:' in line:
            DISCORD_BOT_TOKEN = line.split('BotToken:')[1].strip().strip('"\'')
            break

if not DISCORD_BOT_TOKEN:
    print("❌ Discord bot token not found")
    exit(1)

# Fetch messages from Discord
url = f"https://discord.com/api/v10/channels/{DISCORD_CHANNEL_ID}/messages"
headers = {
    'Authorization': f'Bot {DISCORD_BOT_TOKEN}',
    'Content-Type': 'application/json'
}

# Get last 100 messages (Discord max per request)
params = {'limit': 100}

print("📥 Fetching speed trap messages from Discord...")
try:
    response = requests.get(url, headers=headers, params=params, timeout=10)
    response.raise_for_status()
    messages = response.json()
    print(f"✓ Fetched {len(messages)} messages")
except Exception as e:
    print(f"❌ Error fetching messages: {e}")
    exit(1)

# Parse violations from messages
violations = []
for msg in messages:
    content = msg.get('content', '')
    
    # Check if it's a speed trap violation
    if '**SPEED VIOLATION DETECTED**' not in content:
        continue
    
    # Extract data
    violation = {
        'timestamp': msg.get('timestamp', datetime.now().isoformat()),
        'raw_content': content
    }
    
    lines = content.split('\n')
    for line in lines:
        if '**Driver:**' in line and '`' in line:
            parts = line.split('`')
            if len(parts) >= 2:
                violation['driver'] = parts[1]
        elif '**Speed:**' in line and '`' in line:
            parts = line.split('`')
            if len(parts) >= 2:
                violation['speed'] = parts[1].replace(' km/h', '')
        elif '**Limit:**' in line and '`' in line:
            parts = line.split('`')
            if len(parts) >= 2:
                violation['limit'] = parts[1].replace(' km/h', '')
        elif '**Over Limit:**' in line and '`' in line:
            parts = line.split('`')
            if len(parts) >= 2:
                violation['over_limit'] = parts[1].replace(' km/h', '')
        elif '**Camera:**' in line and '`' in line:
            parts = line.split('`')
            if len(parts) >= 2:
                violation['camera'] = parts[1]
    
    # Only add if we got driver and speed
    if violation.get('driver') and violation.get('speed'):
        violations.append(violation)

print(f"✓ Parsed {len(violations)} valid violations")

# Save to stats file
stats_data = {
    'violations': violations,
    'last_updated': datetime.now().isoformat()
}

with open(STATS_FILE, 'w') as f:
    json.dump(stats_data, f, indent=2)

print(f"✓ Saved {len(violations)} violations to {STATS_FILE}")

# Show summary
if violations:
    drivers = {}
    for v in violations:
        driver = v.get('driver', 'Unknown')
        drivers[driver] = drivers.get(driver, 0) + 1
    
    print(f"\n📊 Top Violators:")
    sorted_drivers = sorted(drivers.items(), key=lambda x: x[1], reverse=True)[:10]
    for driver, count in sorted_drivers:
        print(f"  {driver}: {count} violations")
