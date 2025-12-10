#!/usr/bin/env python3
"""
Recover Speed Trap Data from Discord History
Fetches messages from the speed trap channel and repopulates speed_trap_stats.json
"""

import json
import time
import requests
from pathlib import Path
from datetime import datetime

# Configuration
CHANNEL_ID = "YOUR_DISCORD_CHANNEL_ID"
BOT_TOKEN = "YOUR_DISCORD_BOT_TOKEN"
STATS_FILE = Path(__file__).parent / "speed_trap_stats.json"
LIMIT = 3000  # Max messages to fetch

def fetch_messages():
    """Fetch messages from Discord API"""
    headers = {
        "Authorization": f"Bot {BOT_TOKEN}",
        "Content-Type": "application/json"
    }
    
    url = f"https://discord.com/api/v9/channels/{CHANNEL_ID}/messages?limit=100"
    all_messages = []
    last_id = None
    
    print(f"🚀 Starting recovery (Limit: {LIMIT} messages)...")
    
    while len(all_messages) < LIMIT:
        fetch_url = url
        if last_id:
            fetch_url += f"&before={last_id}"
            
        try:
            response = requests.get(fetch_url, headers=headers)
            if response.status_code == 429:
                retry_after = response.json().get('retry_after', 5)
                print(f"⏱️ Rate limited, waiting {retry_after}s...")
                time.sleep(retry_after)
                continue
                
            if response.status_code != 200:
                print(f"❌ Error {response.status_code}: {response.text}")
                break
                
            messages = response.json()
            if not messages:
                print("✓ Reached end of history")
                break
                
            all_messages.extend(messages)
            last_id = messages[-1]['id']
            print(f"   Fetched {len(all_messages)} messages...")
            
            time.sleep(0.5)  # Be nice to API
            
        except Exception as e:
            print(f"❌ Exception: {e}")
            break
            
    return all_messages

def parse_violation(msg):
    """Extract violation data from message"""
    content = msg.get('content', '')
    
    # Check embeds if content is empty
    if not content and msg.get('embeds'):
        content = msg['embeds'][0].get('description', '')
        
    if not content:
        return None
        
    violation = {
        'timestamp': msg['timestamp'],
        'raw_content': content,
        'driver': 'Unknown',
        'speed': '0',
        'limit': '0',
        'over_limit': '0',
        'camera': 'Unknown'
    }
    
    # Parse lines
    lines = content.split('\n')
    found_data = False
    
    for line in lines:
        if '**Driver:**' in line:
            violation['driver'] = line.split('`')[1] if '`' in line else 'Unknown'
            found_data = True
        elif '**Speed:**' in line:
            violation['speed'] = line.split('`')[1].replace(' km/h', '') if '`' in line else '0'
        elif '**Limit:**' in line:
            violation['limit'] = line.split('`')[1].replace(' km/h', '') if '`' in line else '0'
        elif '**Over Limit:**' in line:
            violation['over_limit'] = line.split('`')[1].replace(' km/h', '') if '`' in line else '0'
        elif '**Camera:**' in line:
            violation['camera'] = line.split('`')[1] if '`' in line else 'Unknown'
            
    if found_data:
        return violation
    return None

def main():
    # 1. Fetch
    messages = fetch_messages()
    print(f"✓ Downloaded {len(messages)} messages")
    
    # 2. Parse
    new_violations = []
    for msg in messages:
        v = parse_violation(msg)
        if v:
            new_violations.append(v)
            
    print(f"✓ Parsed {len(new_violations)} valid violations")
    
    # 3. Load existing
    if STATS_FILE.exists():
        with open(STATS_FILE, 'r') as f:
            data = json.load(f)
            existing = data.get('violations', [])
    else:
        existing = []
        
    # 4. Merge (Avoid duplicates based on timestamp + driver)
    existing_keys = {f"{v['timestamp']}_{v.get('driver')}" for v in existing}
    added_count = 0
    
    for v in new_violations:
        key = f"{v['timestamp']}_{v.get('driver')}"
        if key not in existing_keys:
            existing.append(v)
            existing_keys.add(key)
            added_count += 1
            
    # Sort by timestamp
    existing.sort(key=lambda x: x['timestamp'])
    
    # 5. Save
    with open(STATS_FILE, 'w') as f:
        json.dump({
            'violations': existing,
            'last_updated': datetime.now().isoformat()
        }, f, indent=2)
        
    print(f"✅ Successfully recovered {added_count} new violations!")
    print(f"📊 Total violations in database: {len(existing)}")

if __name__ == "__main__":
    main()
