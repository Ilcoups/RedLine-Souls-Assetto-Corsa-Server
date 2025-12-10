#!/usr/bin/env python3
"""
Honeypot Webhook Server
Pretends to be a Discord webhook, captures attacker info, logs it privately,
and posts a funny sanitized message to the real Discord channel.
"""
import os
import json
import time
import requests
from pathlib import Path
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import parse_qs
import logging

# Load environment
ROOT_DIR = Path(__file__).resolve().parent
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

# Configuration
HONEYPOT_PORT = 8084  # Different from real webhook proxy (8083)
REAL_ALERT_WEBHOOK = os.getenv('DISCORD_WEBHOOK')  # Post alerts to your main Discord
LOG_DIR = Path("/home/acserver/server/logs")
HONEYPOT_LOG = LOG_DIR / "honeypot_catches.log"
HONEYPOT_DATA = LOG_DIR / "honeypot_data.json"

# Logging setup
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s: %(message)s',
    handlers=[
        logging.FileHandler(HONEYPOT_LOG),
        logging.StreamHandler()
    ]
)
log = logging.getLogger(__name__)

# Funny messages to post publicly
FUNNY_MESSAGES = [
    "🍯 **Honeypot Alert!** Someone just tried to use an old deactivated webhook. Nice try, script kiddie! 😂",
    "🚨 **Security Theater!** Caught someone red-handed trying leaked credentials. Better luck next time! 🎭",
    "🎣 **Got 'Em!** Hook, line, and sinker! Someone took the bait. Our honeypot works! 🐝",
    "👀 **Somebody's Watching...\n** ...but we're watching back! Honeypot triggered. Amateur hour! 🕵️",
    "🧁 **Sweet Trap!** Our honeypot caught a curious visitor. Thanks for testing our security! 🍰",
    "⚠️ **Trespassing Detected!** Someone tried using old credentials. Our security team is taking notes! 📝",
    "🐻 **Winnie the Pooh Approves!** Someone dove into our honeypot. Delicious! 🍯",
    "🎪 **Welcome to the Show!** You just triggered our security honeypot. Enjoy your 15 seconds of fame! 🎬"
]

def get_country_from_ip(ip):
    """Get approximate country from IP (without exposing IP)"""
    try:
        # Use a free IP geolocation service
        response = requests.get(f"https://ipapi.co/{ip}/json/", timeout=3)
        if response.status_code == 200:
            data = response.json()
            country = data.get('country_name', 'Unknown')
            region = data.get('region', '')
            return f"{country}" + (f" ({region})" if region else "")
    except:
        pass
    return "Unknown Location"

def save_honeypot_data(data):
    """Save detailed attacker data to private JSON file"""
    try:
        if HONEYPOT_DATA.exists():
            with open(HONEYPOT_DATA, 'r') as f:
                catches = json.load(f)
        else:
            catches = []
        
        catches.append(data)
        
        # Keep last 100 catches
        if len(catches) > 100:
            catches = catches[-100:]
        
        with open(HONEYPOT_DATA, 'w') as f:
            json.dump(catches, f, indent=2)
        
        log.info(f"✓ Saved honeypot catch data ({len(catches)} total catches)")
    except Exception as e:
        log.error(f"Failed to save honeypot data: {e}")

def send_alert(attacker_info):
    """Send funny sanitized alert to Discord"""
    if not REAL_ALERT_WEBHOOK:
        log.warning("DISCORD_WEBHOOK not set, skipping public alert")
        return
    
    try:
        import random
        funny_msg = random.choice(FUNNY_MESSAGES)
        
        # Sanitized info (NO IP, just general location and timing)
        location = attacker_info.get('location', 'Unknown')
        timestamp = attacker_info.get('timestamp', 'Unknown')
        attempt_count = attacker_info.get('attempt_number', 1)
        
        embed = {
            "title": "🍯 Security Honeypot Triggered!",
            "description": funny_msg,
            "color": 0xff9900,  # Orange
            "fields": [
                {
                    "name": "🌍 Approximate Location",
                    "value": location,
                    "inline": True
                },
                {
                    "name": "🕒 Time",
                    "value": timestamp.split('T')[1].split('.')[0] + " UTC",
                    "inline": True
                },
                {
                    "name": "📊 Total Attempts",
                    "value": str(attempt_count),
                    "inline": True
                }
            ],
            "footer": {
                "text": "RedLine Security Team • Honeypot Detection System"
            },
            "timestamp": timestamp
        }
        
        response = requests.post(
            REAL_ALERT_WEBHOOK,
            json={"embeds": [embed]},
            timeout=5
        )
        
        if response.status_code in [200, 204]:
            log.info("✓ Posted sanitized alert to Discord")
        else:
            log.warning(f"Discord alert failed: {response.status_code}")
            
    except Exception as e:
        log.error(f"Failed to send alert: {e}")

class HoneypotWebhookHandler(BaseHTTPRequestHandler):
    """HTTP handler that pretends to be Discord webhook"""
    
    def log_message(self, format, *args):
        """Override to use our logger"""
        pass
    
    def do_POST(self):
        """Handle POST requests (webhook attempts)"""
        try:
            # Capture all the juicy details
            attacker_info = {
                'timestamp': datetime.utcnow().isoformat(),
                'ip': self.client_address[0],
                'port': self.client_address[1],
                'user_agent': self.headers.get('User-Agent', 'Unknown'),
                'content_type': self.headers.get('Content-Type', 'Unknown'),
                'headers': dict(self.headers),
                'path': self.path,
                'method': 'POST'
            }
            
            # Try to read the body (what they were trying to post)
            try:
                content_length = int(self.headers.get('Content-Length', 0))
                if content_length > 0:
                    body = self.rfile.read(content_length).decode('utf-8', errors='ignore')
                    attacker_info['body'] = body
                    # Try to parse as JSON
                    try:
                        attacker_info['parsed_body'] = json.loads(body)
                    except:
                        pass
            except Exception as e:
                log.warning(f"Could not read request body: {e}")
            
            # Get location (generalized)
            location = get_country_from_ip(attacker_info['ip'])
            attacker_info['location'] = location
            
            # Count total attempts
            if HONEYPOT_DATA.exists():
                with open(HONEYPOT_DATA, 'r') as f:
                    catches = json.load(f)
                attacker_info['attempt_number'] = len(catches) + 1
            else:
                attacker_info['attempt_number'] = 1
            
            # Log the catch
            log.warning("=" * 60)
            log.warning("🚨 HONEYPOT TRIGGERED!")
            log.warning(f"   IP: {attacker_info['ip']}")
            log.warning(f"   Location: {location}")
            log.warning(f"   User-Agent: {attacker_info['user_agent']}")
            log.warning(f"   Attempt #{attacker_info['attempt_number']}")
            log.warning("=" * 60)
            
            # Save detailed data privately
            save_honeypot_data(attacker_info)
            
            # Send funny sanitized alert to Discord
            send_alert(attacker_info)
            
            # Respond like a real Discord webhook to not tip them off
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            
            # Return fake Discord response
            fake_response = {
                "id": "000000000000000000",
                "type": 0,
                "content": "OK",
                "channel_id": "000000000000000000",
                "author": {
                    "bot": True,
                    "id": "000000000000000000",
                    "username": "Webhook"
                },
                "timestamp": datetime.utcnow().isoformat()
            }
            
            self.wfile.write(json.dumps(fake_response).encode())
            
        except Exception as e:
            log.error(f"Error handling honeypot request: {e}")
            self.send_response(500)
            self.end_headers()
    
    def do_GET(self):
        """Handle GET requests"""
        # Log but don't alert (probably just checking if webhook exists)
        log.info(f"GET request from {self.client_address[0]} - {self.headers.get('User-Agent')}")
        
        # Return fake webhook info
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        
        fake_webhook = {
            "type": 1,
            "id": "000000000000000000",
            "name": "RedLine Webhook",
            "avatar": None,
            "channel_id": "000000000000000000",
            "guild_id": "000000000000000000",
            "application_id": None,
            "token": "REDACTED"
        }
        
        self.wfile.write(json.dumps(fake_webhook).encode())

def start_honeypot():
    """Start the honeypot webhook server"""
    try:
        server = HTTPServer(('0.0.0.0', HONEYPOT_PORT), HoneypotWebhookHandler)
        log.info("=" * 70)
        log.info("🍯 Honeypot Webhook Server Starting")
        log.info("=" * 70)
        log.info(f"✓ Listening on http://0.0.0.0:{HONEYPOT_PORT}")
        log.info(f"✓ Catches will be logged to: {HONEYPOT_LOG}")
        log.info(f"✓ Detailed data saved to: {HONEYPOT_DATA}")
        if REAL_ALERT_WEBHOOK:
            log.info(f"✓ Alerts will be posted to Discord")
        else:
            log.warning("⚠ DISCORD_WEBHOOK not set, alerts disabled")
        log.info("=" * 70)
        
        server.serve_forever()
    except Exception as e:
        log.error(f"Failed to start honeypot server: {e}")
        return None

if __name__ == "__main__":
    start_honeypot()
