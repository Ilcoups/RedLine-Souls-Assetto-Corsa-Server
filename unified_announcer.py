#!/usr/bin/env python3
"""
RedLine Souls - Unified Announcer
Handles Discord notifications + Spawn Audio + Chat announcements
NO DUPLICATE MESSAGES - Single source of truth
"""

import re
import time
import socket
import struct
import requests
from pathlib import Path
from datetime import datetime, timezone
import os

# Load environment variables from .env file (fallback loader - no dependencies)
env_path = Path('/home/acserver/server/.env')
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
    print("⚠ Warning: .env file not found at {env_path}")

# Configuration
LOG_DIR = Path("/home/acserver/server/logs")
DISCORD_WEBHOOK = os.getenv('DISCORD_WEBHOOK')
DISCORD_CHAT_WEBHOOK = os.getenv('DISCORD_CHAT_WEBHOOK')
UDP_PLUGIN_HOST = os.getenv('UDP_PLUGIN_HOST', "127.0.0.1")
UDP_PLUGIN_PORT = int(os.getenv('UDP_PLUGIN_PORT', '12001'))  # AssettoServer UDP_PLUGIN_ADDRESS port
CHECK_INTERVAL = 0.5

# Validate critical configuration
if not DISCORD_WEBHOOK:
    print("⚠ WARNING: DISCORD_WEBHOOK not set! Player join/leave notifications disabled.")
    print("   Set DISCORD_WEBHOOK in .env file to enable Discord notifications.")
if not DISCORD_CHAT_WEBHOOK:
    print("⚠ WARNING: DISCORD_CHAT_WEBHOOK not set! Chat notifications disabled.")

print(f"✓ Configuration loaded:")
print(f"  - Discord Events: {'Enabled' if DISCORD_WEBHOOK else 'DISABLED'}")
print(f"  - Discord Chat: {'Enabled' if DISCORD_CHAT_WEBHOOK else 'DISABLED'}")
print(f"  - UDP Plugin: {UDP_PLUGIN_HOST}:{UDP_PLUGIN_PORT}")
print(f"  - Log Directory: {LOG_DIR}")

# Globals
last_position = 0
last_log_file = None
udp_socket = None
# Track active player sessions: {steam_id: {name, join_time, car, discord_message_id}}
active_sessions = {}
triggered_players = set()  # Track who got audio trigger today
recent_events = {}  # Track recent events to prevent spam: {event_key: timestamp}

# ============================================================================
# UDP Plugin Interface - Chat Messages
# ============================================================================

def udp_connect():
    """Initialize UDP socket"""
    global udp_socket
    try:
        udp_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        print(f"✓ UDP socket ready: {UDP_PLUGIN_HOST}:{UDP_PLUGIN_PORT}")
        return True
    except Exception as e:
        print(f"✗ UDP socket error: {e}")
        return False

def send_chat(message, hidden=False):
    """
    Send chat message via UDP Plugin Interface
    If hidden=True, uses CSP hidden format ($CSP$ prefix)
    """
    global udp_socket
    
    if not udp_socket:
        if not udp_connect():
            return False
    
    try:
        # CSP hidden messages start with $CSP$ and won't show in chat
        if hidden:
            message = f"$CSP${message}"
        
        # Build UDP packet for broadcast chat (0xCB)
        packet = struct.pack('B', 0xCB)
        
        # Encode message as UTF-8
        message_bytes = message.encode('utf-8')
        packet += struct.pack('<I', len(message_bytes))
        packet += message_bytes
        packet += b'\x00'
        
        # Send to server
        udp_socket.sendto(packet, (UDP_PLUGIN_HOST, UDP_PLUGIN_PORT))
        
        if not hidden:
            print(f"✓ Chat: {message}")
        
        return True
        
    except Exception as e:
        print(f"✗ UDP chat error: {e}")
        return False

# ============================================================================
# Event Rate Limiting
# ============================================================================

def should_process_event(event_key, cooldown_seconds=60):
    """
    Check if we should process this event or if it's too soon (spam prevention)
    Returns True if event should be processed, False if it's a duplicate/spam
    """
    global recent_events
    
    current_time = time.time()
    
    # Clean up old events (older than 5 minutes)
    recent_events = {k: v for k, v in recent_events.items() if current_time - v < 300}
    
    # Check if this event was processed recently
    if event_key in recent_events:
        time_since = current_time - recent_events[event_key]
        if time_since < cooldown_seconds:
            # Too soon - skip this event
            return False
    
    # Process this event and record timestamp
    recent_events[event_key] = current_time
    return True

# ============================================================================
# Discord Implementation
# ============================================================================

def extract_webhook_parts(webhook_url):
    """Extract webhook ID and token from webhook URL"""
    try:
        # Format: https://discord.com/api/webhooks/{id}/{token}
        match = re.search(r'/webhooks/(\d+)/([^/]+)', webhook_url)
        if match:
            return match.group(1), match.group(2)
    except Exception:
        pass
    return None, None

def send_discord_event(message_type, player_name, steam_id=None, car=None, join_time=None, leave_time=None):
    """Send rich embedded message to Discord events webhook
    Returns message ID if successful, None otherwise"""
    try:
        embed = {}
        
        if message_type == "join":
            embed = {
                "title": f"🟢 {player_name} joined the server",
                "color": 0x00ff00,
                "description": "*Waiting for session completion...*",
                "fields": [
                    {
                        "name": "🚗 Car",
                        "value": car if car else "Unknown",
                        "inline": True
                    }
                ],
                "footer": {
                    "text": f"Steam ID: {steam_id}" if steam_id else "RedLine Souls"
                },
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
            
            if steam_id:
                embed["fields"].append({
                    "name": "👤 Steam Profile",
                    "value": f"[View Profile](https://steamcommunity.com/profiles/{steam_id})",
                    "inline": True
                })
                
        elif message_type == "leave":
            embed = {
                "title": f"🔴 {player_name} left the server",
                "color": 0xff0000,
                "footer": {
                    "text": "RedLine Souls"
                },
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
            
        elif message_type == "session_complete":
            # Calculate duration
            if join_time and leave_time:
                duration_seconds = (leave_time - join_time).total_seconds()
                hours, remainder = divmod(int(duration_seconds), 3600)
                minutes, seconds = divmod(remainder, 60)
                duration_str = f"{hours}h {minutes}m {seconds}s" if hours > 0 else f"{minutes}m {seconds}s"
            else:
                duration_str = "Unknown"
            
            # Format times
            join_ts = join_time.strftime('%H:%M:%S UTC') if join_time else 'unknown'
            leave_ts = leave_time.strftime('%H:%M:%S UTC') if leave_time else 'unknown'
            
            embed = {
                "title": f"🚗 {player_name} completed session",
                "color": 0x0099ff,
                "description": f"**Joined:** {join_ts} | **Left:** {leave_ts}",
                "fields": [
                    {
                        "name": "🚗 Car",
                        "value": car if car else "Unknown",
                        "inline": True
                    },
                    {
                        "name": "⏱️ Session Duration",
                        "value": duration_str,
                        "inline": True
                    }
                ],
                "footer": {
                    "text": f"Steam ID: {steam_id}" if steam_id else "RedLine Souls"
                },
                "timestamp": leave_time.isoformat() if leave_time else datetime.now(timezone.utc).isoformat()
            }
            
            if steam_id:
                embed["fields"].append({
                    "name": "👤 Steam Profile",
                    "value": f"[View Profile](https://steamcommunity.com/profiles/{steam_id})",
                    "inline": True
                })
        
        # Only attempt to post if webhook configured
        if not DISCORD_WEBHOOK:
            print(f"⚠ Discord events webhook not configured; skipping {message_type} for {player_name}")
            return None

        # Send embed with ?wait=true to get message ID back
        # This is CRITICAL for editing the message later!
        webhook_url = DISCORD_WEBHOOK
        if '?' not in webhook_url:
            webhook_url += '?wait=true'
        elif 'wait=' not in webhook_url:
            webhook_url += '&wait=true'
        
        data = {"embeds": [embed]}
        response = requests.post(webhook_url, json=data, timeout=5)

        if response.status_code in [200, 204]:
            print(f"✓ Discord: {message_type.upper()} - {player_name}")
            # Extract message ID from response (should work now with wait=true)
            try:
                response_data = response.json()
                message_id = response_data.get('id')
                if message_id:
                    print(f"  → Got message ID: {message_id} (can edit later)")
                    return message_id
                else:
                    print(f"  ⚠ No message ID in response (editing won't work)")
                    return None
            except Exception as e:
                print(f"  ⚠ Could not parse response for message ID: {e}")
                return None
        else:
            print(f"✗ Discord POST failed: {response.status_code}")
            return None
        
    except Exception as e:
        print(f"✗ Discord error: {e}")
        return None

def edit_discord_message(message_id, player_name, steam_id=None, car=None, join_time=None, leave_time=None):
    """Edit an existing Discord message with session completion info"""
    try:
        if not DISCORD_WEBHOOK or not message_id:
            return False
            
        # Extract webhook ID and token
        webhook_id, webhook_token = extract_webhook_parts(DISCORD_WEBHOOK)
        if not webhook_id or not webhook_token:
            print(f"✗ Cannot extract webhook parts from URL")
            return False
        
        # Calculate duration
        if join_time and leave_time:
            duration_seconds = (leave_time - join_time).total_seconds()
            hours, remainder = divmod(int(duration_seconds), 3600)
            minutes, seconds = divmod(remainder, 60)
            duration_str = f"{hours}h {minutes}m {seconds}s" if hours > 0 else f"{minutes}m {seconds}s"
        else:
            duration_str = "Unknown"
        
        # Format times
        join_ts = join_time.strftime('%H:%M:%S UTC') if join_time else 'unknown'
        leave_ts = leave_time.strftime('%H:%M:%S UTC') if leave_time else 'unknown'
        
        # Create updated embed
        embed = {
            "title": f"🚗 {player_name} completed session",
            "color": 0x0099ff,
            "description": f"**Joined:** {join_ts} | **Left:** {leave_ts}",
            "fields": [
                {
                    "name": "🚗 Car",
                    "value": car if car else "Unknown",
                    "inline": True
                },
                {
                    "name": "⏱️ Session Duration",
                    "value": duration_str,
                    "inline": True
                }
            ],
            "footer": {
                "text": f"Steam ID: {steam_id}" if steam_id else "RedLine Souls"
            },
            "timestamp": leave_time.isoformat() if leave_time else datetime.now(timezone.utc).isoformat()
        }
        
        if steam_id:
            embed["fields"].append({
                "name": "👤 Steam Profile",
                "value": f"[View Profile](https://steamcommunity.com/profiles/{steam_id})",
                "inline": True
            })
        
        # Edit message via webhook
        edit_url = f"https://discord.com/api/webhooks/{webhook_id}/{webhook_token}/messages/{message_id}"
        data = {"embeds": [embed]}
        response = requests.patch(edit_url, json=data, timeout=5)
        
        if response.status_code in [200, 204]:
            print(f"✓ Discord: EDITED message for {player_name}")
            return True
        else:
            print(f"✗ Discord PATCH failed: {response.status_code} - {response.text[:100]}")
            return False
            
    except Exception as e:
        print(f"✗ Discord edit error: {e}")
        return False

def send_discord_chat(message, player_name=None):
    """Send in-game chat message to Discord chat webhook"""
    try:
        if not message or not message.strip():
            return
        
        # Format the message
        if player_name:
            content = f"**{player_name}**: {message}"
        else:
            content = message
        
        # Limit length
        if len(content) > 2000:
            content = content[:1997] + "..."
        
        if not DISCORD_CHAT_WEBHOOK:
            print("⚠ Discord chat webhook not configured; skipping chat post")
            return

        data = {"content": content}
        response = requests.post(DISCORD_CHAT_WEBHOOK, json=data, timeout=5)

        if response.status_code in [200, 204]:
            print(f"✓ Discord Chat: {content[:80]}")
            
    except Exception as e:
        print(f"✗ Discord Chat error: {e}")

# ============================================================================
# Log Monitoring
# ============================================================================

def get_current_log_file():
    today = datetime.now().strftime("%Y%m%d")
    return LOG_DIR / f"log-{today}.txt"

def monitor_logs():
    global last_position, last_log_file, triggered_players
    
    log_file = get_current_log_file()
    
    if log_file != last_log_file:
        last_log_file = log_file
        print(f"Monitoring: {log_file}")
        
        # Start from end of file to avoid re-processing old entries
        if log_file.exists():
            with open(log_file, 'r', encoding='utf-8') as f:
                f.seek(0, 2)
                last_position = f.tell()
        else:
            last_position = 0
        
        # Reset triggered players on new day
        triggered_players.clear()
    
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
    """Process log line for player events and chat messages"""
    
    # Player connection: PlayerName (76561198012345678, slot (car-skin)) has connected
    if " has connected" in line and "[INF]" in line:
        match = re.search(r'\[INF\]\s+(.+?)\s+\((\d+),\s+\d+\s+\((.+?)\)', line)
        if match:
            player_name = match.group(1).strip()
            steam_id = match.group(2)
            car = match.group(3).split('-')[0] if '-' in match.group(3) else match.group(3)
            car_display = car.split('/')[0] if '/' in car else car
            
            # Rate limit: only process if not seen in last 5 seconds
            event_key = f"join:{steam_id}"
            if not should_process_event(event_key, cooldown_seconds=5):
                return  # Skip duplicate
            
            # Store session info
            join_time = datetime.now(timezone.utc)
            active_sessions[steam_id] = {
                'name': player_name,
                'join_time': join_time,
                'car': car_display,
                'discord_message_id': None
            }
            
            # Post join message to Discord and store message ID
            message_id = send_discord_event("join", player_name, steam_id=steam_id, car=car_display)
            if message_id:
                active_sessions[steam_id]['discord_message_id'] = message_id
            
            print(f"✓ Session started: {player_name} ({steam_id})")
            
            # Send HIDDEN audio trigger if first time today
            if steam_id not in triggered_players:
                send_chat(f"SPAWN_AUDIO|{steam_id}", hidden=True)
                triggered_players.add(steam_id)
    
    # Player disconnection
    elif " has disconnected" in line and "[INF]" in line:
        match = re.search(r'\[INF\]\s+(.+?)\s+has disconnected', line)
        if match:
            player_name = match.group(1).strip()
            
            # Rate limit: only process if not seen in last 5 seconds
            event_key = f"leave:{player_name}"
            if not should_process_event(event_key, cooldown_seconds=5):
                return  # Skip duplicate
            
            # Find session info by player name (since steam_id might not be in disconnect message)
            session_info = None
            steam_id = None
            for sid, info in active_sessions.items():
                if info['name'] == player_name:
                    session_info = info
                    steam_id = sid
                    break
            
            leave_time = datetime.now(timezone.utc)
            
            if session_info and steam_id:
                # Try to edit the original join message instead of posting new one
                message_id = session_info.get('discord_message_id')
                
                if message_id:
                    # Edit the existing join message with session completion info
                    success = edit_discord_message(
                        message_id, 
                        player_name,
                        steam_id=steam_id,
                        car=session_info['car'],
                        join_time=session_info['join_time'],
                        leave_time=leave_time
                    )
                    
                    if not success:
                        # If editing failed, fall back to posting new message
                        print(f"⚠ Edit failed, posting new message for {player_name}")
                        send_discord_event("session_complete", player_name,
                                         steam_id=steam_id,
                                         car=session_info['car'],
                                         join_time=session_info['join_time'],
                                         leave_time=leave_time)
                else:
                    # No message ID stored, post new message
                    send_discord_event("session_complete", player_name,
                                     steam_id=steam_id,
                                     car=session_info['car'],
                                     join_time=session_info['join_time'],
                                     leave_time=leave_time)
                
                # Remove from active sessions
                del active_sessions[steam_id]
                print(f"✓ Session completed: {player_name} ({steam_id})")
            else:
                # Fallback: player left without proper join record (server restart, etc.)
                send_discord_event("leave", player_name)
                print(f"⚠ Session incomplete: {player_name} (no join record found)")
            
            # Send to in-game chat: a combined session summary when we have a join record
            if session_info and steam_id:
                # Format join time and duration for chat
                jt = session_info['join_time']
                leave_t = leave_time
                duration_seconds = int((leave_t - jt).total_seconds()) if jt else None
                if duration_seconds is not None:
                    hours, remainder = divmod(duration_seconds, 3600)
                    minutes, seconds = divmod(remainder, 60)
                    duration_str = f"{hours}h {minutes}m {seconds}s" if hours > 0 else f"{minutes}m {seconds}s"
                else:
                    duration_str = "unknown"

                join_ts = jt.strftime('%H:%M:%S UTC') if jt else 'unknown'
                chat_msg = f"🚗 {player_name} — joined {join_ts}, session {duration_str}"
                send_chat(chat_msg)
            else:
                # Fallback: simple left message
                send_chat(f"🔴 {player_name} left the server")
    
    # Checksum failure - RATE LIMITED to prevent spam
    elif "checksum" in line.lower() and ("fail" in line.lower() or "error" in line.lower() or "mismatch" in line.lower()):
        match = re.search(r'(\w+).*checksum', line, re.IGNORECASE)
        if match:
            player_name = match.group(1).strip()
            
            # Rate limit: only send ONE checksum message per player per 60 seconds
            event_key = f"checksum:{player_name}"
            if not should_process_event(event_key, cooldown_seconds=60):
                # Spam detected - log it but don't send to Discord
                print(f"⚠ Checksum spam suppressed for {player_name}")
                return
            
            # Send to Discord (only once per minute per player)
            embed = {
                "title": f"⚠️ {player_name} - Checksum Failed",
                "description": "Player has modified car files or outdated content",
                "color": 0xffaa00,
                "footer": {"text": "Player cannot join until files match server"},
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
            try:
                data = {"embeds": [embed]}
                if DISCORD_WEBHOOK:
                    requests.post(DISCORD_WEBHOOK, json=data, timeout=5)
                    print(f"✓ Discord: CHECKSUM FAIL - {player_name}")
                else:
                    print(f"⚠ Discord events webhook not configured; skipping checksum fail for {player_name}")
            except Exception as e:
                print(f"✗ Discord checksum error: {e}")
    
    # Player chat messages: [INF] CHAT: PlayerName (SlotID): message
    elif "CHAT:" in line and "[INF]" in line:
        match = re.search(r'\[INF\] CHAT:\s+(.+?)\s+\(\d+\):\s+(.+)', line)
        if match:
            player_name = match.group(1).strip()
            message = match.group(2).strip()
            
            # Skip CSP internal messages
            if not message.startswith('$CSP'):
                # Send to Discord chat webhook
                send_discord_chat(message, player_name)

# ============================================================================
# Main
# ============================================================================

def main():
    print("=" * 70)
    print("RedLine Souls - Unified Announcer")
    print("Discord Events + Chat + Spawn Audio Trigger")
    print("=" * 70)
    print(f"UDP Plugin: {UDP_PLUGIN_HOST}:{UDP_PLUGIN_PORT}")
    # Do not print full webhook URLs to logs; mask them for security
    def mask_url(u):
        try:
            return u.split('/webhooks/')[-1][:6] + '...' if u and '/webhooks/' in u else '[REDACTED]'
        except Exception:
            return '[REDACTED]'

    print(f"Discord Events: {mask_url(DISCORD_WEBHOOK)}")
    print(f"Discord Chat: {mask_url(DISCORD_CHAT_WEBHOOK)}")
    print(f"Logs: {LOG_DIR}")
    print()
    
    # Initialize UDP
    if udp_connect():
        print("✓ UDP connection ready")
    else:
        print("⚠ UDP initialization failed - will retry on first message")
    
    print()
    print("Monitoring for player events...")
    print()
    
    try:
        while True:
            monitor_logs()
            time.sleep(CHECK_INTERVAL)
    except KeyboardInterrupt:
        print("\n\nShutting down...")
        if udp_socket:
            udp_socket.close()

import sys
def run_test():
    # Usage: --test-join <name> <steam_id> <car>
    #        --test-leave <name> <steam_id> <car>
    #        --test-summary <name> <steam_id> <car> <duration_seconds>
    from pathlib import Path
    args = sys.argv
    test_flag_file = Path('.test_announcer_flag')
    if test_flag_file.exists():
        print('⚠ Test post already sent in this session. Remove .test_announcer_flag to re-run.')
        return
    did_post = False
    if '--test-join' in args:
        idx = args.index('--test-join')
        try:
            name, steam_id, car = args[idx+1:idx+4]
        except Exception:
            print('Usage: --test-join <name> <steam_id> <car>')
            return
        send_discord_event('join', name, steam_id=steam_id, car=car)
        send_chat(f"🟢 {name} joined the server")
        print('Test join sent.')
        did_post = True
    if '--test-leave' in args:
        idx = args.index('--test-leave')
        try:
            name, steam_id, car = args[idx+1:idx+4]
        except Exception:
            print('Usage: --test-leave <name> <steam_id> <car>')
            return
        send_discord_event('leave', name, steam_id=steam_id, car=car)
        send_chat(f"🔴 {name} left the server")
        print('Test leave sent.')
        did_post = True
    if '--test-summary' in args:
        idx = args.index('--test-summary')
        try:
            name, steam_id, car, duration = args[idx+1:idx+5]
            from datetime import datetime, timedelta, timezone
            join_time = datetime.now(timezone.utc) - timedelta(seconds=int(duration))
            leave_time = datetime.now(timezone.utc)
        except Exception:
            print('Usage: --test-summary <name> <steam_id> <car> <duration_seconds>')
            return
        send_discord_event('session_complete', name, steam_id=steam_id, car=car, join_time=join_time, leave_time=leave_time)
        chat_msg = f"🔴 {name} left — joined at {join_time.strftime('%Y-%m-%d %H:%M:%S UTC')}, session {int(duration)//60}m {int(duration)%60}s"
        send_chat(chat_msg)
        print('Test summary sent.')
        did_post = True
    if did_post:
        test_flag_file.write_text('posted')
        print('✓ Test post sent. Exiting.')
        return
    main()

if __name__ == "__main__":
    run_test()

