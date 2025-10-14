#!/usr/bin/env python3
"""Test script to send leaderboard immediately"""

import sys
sys.path.insert(0, '/home/acserver/server')

from player_stats import generate_leaderboard, DISCORD_STATS_WEBHOOK
import requests

print("Generating test leaderboard...")
embed = generate_leaderboard()

if embed:
    print("Leaderboard data:")
    print(f"  Title: {embed['title']}")
    print(f"  Fields: {len(embed['fields'])}")
    
    print("\nSending to Discord...")
    response = requests.post(DISCORD_STATS_WEBHOOK, json={"embeds": [embed]}, timeout=10)
    
    if response.status_code in [200, 204]:
        print("✓ Test leaderboard sent successfully!")
    else:
        print(f"✗ Discord error: {response.status_code}")
        print(response.text)
else:
    print("✗ No stats to display")
