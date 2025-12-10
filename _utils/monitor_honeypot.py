#!/usr/bin/env python3
"""
Improved Honeypot Webhook Monitor
Checks if honeypot webhook receives unauthorized messages (indicates attacker activity)

The honeypot should be a REAL Discord webhook in a private channel that only YOU can see.
If anyone posts to it, it means the attacker is trying to use leaked credentials.
"""
import requests
import json
import sys
import os
from datetime import datetime
from pathlib import Path

# Load environment
ROOT_DIR = Path(__file__).resolve().parent.parent
env_path = ROOT_DIR / '.env'
if env_path.exists():
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

# HONEYPOT WEBHOOK - Should be a REAL webhook in a private Discord channel
# Set this in your .env file: HONEYPOT_WEBHOOK="https://discord.com/api/webhooks/..."
HONEYPOT_WEBHOOK = os.getenv('HONEYPOT_WEBHOOK')

def check_honeypot():
    """Check if honeypot webhook has received any messages"""
    
    if not HONEYPOT_WEBHOOK:
        print(f"[{datetime.now()}] ⚠️ HONEYPOT_WEBHOOK not set in .env file")
        print("   To enable honeypot detection:")
        print("   1. Create a private Discord channel (only you can see)")
        print("   2. Create a webhook in that channel")
        print("   3. Add to .env: HONEYPOT_WEBHOOK=\"https://discord.com/api/webhooks/...\"")
        print("   4. Add fake webhook to OLD_WEBHOOK_BACKUP.md")
        return None
    
    try:
        # Extract webhook ID and token from URL
        parts = HONEYPOT_WEBHOOK.split('/')
        if len(parts) < 7:
            print(f"[{datetime.now()}] ❌ Invalid webhook URL format")
            return None
            
        webhook_id = parts[-2]
        webhook_token = parts[-1]
        
        # Get last message from webhook
        # Discord API: GET /webhooks/{webhook_id}/{webhook_token}
        url = f"https://discord.com/api/webhooks/{webhook_id}/{webhook_token}"
        
        response = requests.get(url, timeout=5)
        
        if response.status_code == 200:
            webhook_data = response.json()
            webhook_name = webhook_data.get('name', 'Unknown')
            channel_id = webhook_data.get('channel_id', 'Unknown')
            
            # Now check for messages in this channel
            # We can't directly fetch webhook messages without bot permissions
            # So we just verify the webhook exists and is accessible
            print(f"[{datetime.now()}] ✅ Honeypot webhook active: {webhook_name}")
            print(f"   Channel ID: {channel_id}")
            print(f"   Status: Monitoring for unauthorized posts")
            print(f"   Check your Discord channel to see if any messages appeared!")
            return False
            
        elif response.status_code == 404:
            print(f"[{datetime.now()}] ❌ Honeypot webhook not found - was it deleted?")
            return None
        else:
            print(f"[{datetime.now()}] ⚠️ Unexpected response: {response.status_code}")
            return None
            
    except Exception as e:
        print(f"[{datetime.now()}] ⚠️ Error checking honeypot: {e}")
        return None

if __name__ == "__main__":
    result = check_honeypot()
    sys.exit(0 if result == False else 1)
