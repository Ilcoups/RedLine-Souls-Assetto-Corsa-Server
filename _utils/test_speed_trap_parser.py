#!/usr/bin/env python3
"""Test speed trap stats parser with sample data"""
import json
import requests

# Sample webhook payload (multipart format with image)
test_payload = {
    "content": """**━━━━━━━━━━━━━━━━━━━━━**
🚓 **SPEED VIOLATION DETECTED** 🚓
**━━━━━━━━━━━━━━━━━━━━━**

📸 **Camera:** `#100-005`
👤 **Driver:** `TestDriver`
⚡ **Speed:** `150 km/h`
⚠️ **Limit:** `80 km/h`
📊 **Over Limit:** `70 km/h`

💸 *You have been fined for reckless driving*"""
}

# Send to local proxy
url = "http://127.0.0.1:8083/webhook"

# Simulate multipart upload (how Discord plugin sends it)
files = {
    'payload_json': (None, json.dumps(test_payload), 'application/json'),
    'file': ('test.png', b'fake_image_data', 'image/png')
}

try:
    response = requests.post(url, files=files, timeout=5)
    print(f"✓ Response: {response.status_code}")
    print(f"  {response.json()}")
except Exception as e:
    print(f"❌ Error: {e}")

# Check if stats file updated
import time
time.sleep(1)

with open('/home/acserver/server/_utils/speed_trap_stats.json', 'r') as f:
    data = json.load(f)
    print(f"\\n✓ Stats file now has {len(data['violations'])} violations")
    if data['violations']:
        latest = data['violations'][-1]
        print(f"  Latest: {latest.get('driver')} @ {latest.get('speed')} km/h")
