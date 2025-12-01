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
import json
import pytz
from pathlib import Path
from datetime import datetime, timezone
import os

# Load environment variables from .env file (fallback loader - no dependencies)
ROOT_DIR = Path(__file__).resolve().parent
env_path = ROOT_DIR / '.env'
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
LOG_DIR = ROOT_DIR / "logs"
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
# Track active player sessions: {steam_id: {name, join_time, car, discord_message_id, poll_asked, poll_voted}}
active_sessions = {}
triggered_players = set()  # Track who got audio trigger today
recent_events = {}  # Track recent events to prevent spam: {event_key: timestamp}
# Track checksum failures: {player_name: {attempts: count, message_id: discord_message_id, first_attempt_time: timestamp}}
checksum_failures = {}
# Traffic poll tracking
# Ask at different milestones: 10min, 30min, 90min (1.5hr), 180min (3hr)
# This gives more weight to longer sessions without being annoying
POLL_MILESTONES = [10, 30, 90, 180]  # minutes
VOTES_FILE = ROOT_DIR / "traffic_votes.json"

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
# Traffic Poll System
# ============================================================================

def load_votes():
    """Load existing votes from JSON file"""
    if VOTES_FILE.exists():
        try:
            with open(VOTES_FILE, 'r') as f:
                return json.load(f)
        except:
            return {}
    return {}

def get_traffic_period():
    """Get current traffic period (night/morning/afternoon/evening)"""
    # Use Amsterdam timezone (same as dynamic_traffic.py)
    import pytz
    amsterdam_tz = pytz.timezone('Europe/Amsterdam')
    hour = datetime.now(amsterdam_tz).hour
    
    if 0 <= hour < 6:
        return "night"
    elif 6 <= hour < 12:
        return "morning"
    elif 12 <= hour < 18:
        return "afternoon"
    else:
        return "evening"

def is_regular_player(steam_id):
    """Check if player is a 'regular' (has stats from player_stats.py)"""
    try:
        stats_file = ROOT_DIR / "player_stats.json"
        if not stats_file.exists():
            return False
        
        with open(stats_file, 'r') as f:
            stats = json.load(f)
        
        # Check all_time stats
        if steam_id in stats.get("all_time", {}):
            player_data = stats["all_time"][steam_id]
            # Regular = played at least 2 hours total AND joined 3+ times
            total_playtime = player_data.get("playtime", 0)
            join_count = player_data.get("join_count", 0)
            
            if total_playtime >= 7200 and join_count >= 3:  # 2+ hours, 3+ sessions
                return True
        
        return False
    except Exception as e:
        print(f"⚠ Error checking regular status: {e}")
        return False

def save_vote(steam_id, player_name, rating, session_duration=None):
    """Save a traffic rating vote with weighted metadata"""
    today = datetime.now(timezone.utc).strftime('%Y-%m-%d')
    
    votes = load_votes()
    if today not in votes:
        votes[today] = []
    
    # Get current traffic period
    current_period = get_traffic_period()
    
    # Get session duration if not provided
    if session_duration is None:
        session = active_sessions.get(steam_id, {})
        join_time = session.get('join_time')
        if not join_time:
            print(f"⚠ Poll: No join time for {player_name}")
            return False
        session_duration = (datetime.now(timezone.utc) - join_time).total_seconds() / 60
    
    # Calculate vote weight: min(session_minutes / 30, 3.0)
    # 30 min = 1.0x weight (baseline)
    # Cap at 3.0x to prevent one player dominating
    vote_weight = min(session_duration / 30.0, 3.0)
    
    # Check if regular player
    is_regular = is_regular_player(steam_id)
    
    vote_data = {
        'steam_id': steam_id,
        'player_name': player_name,
        'rating': rating,
        'timestamp': datetime.now(timezone.utc).isoformat(),
        'session_minutes': round(session_duration, 1),
        'vote_weight': round(vote_weight, 2),
        'traffic_period': current_period,
        'is_regular': is_regular
    }
    
    votes[today].append(vote_data)
    
    try:
        with open(VOTES_FILE, 'w') as f:
            json.dump(votes, f, indent=2)
        print(f"✓ Poll: {player_name} voted {rating}/5 (weight: {vote_weight:.2f}x)")
        return True
    except Exception as e:
        print(f"✗ Poll save error: {e}")
        return False

def check_and_send_polls():
    """Check if any players need to be asked for traffic feedback at milestones"""
    global active_sessions
    current_time = datetime.now(timezone.utc)
    
    for steam_id, session in active_sessions.items():
        join_time = session.get('join_time')
        if not join_time:
            continue
        
        time_playing = (current_time - join_time).total_seconds() / 60  # minutes
        polls_asked = session.get('polls_asked', [])
        
        # Check each milestone
        for milestone in POLL_MILESTONES:
            # If player has been playing long enough for this milestone
            # and we haven't asked at this milestone yet
            if time_playing >= milestone and milestone not in polls_asked:
                player_name = session['name']
                
                # Different messages based on milestone
                if milestone == 10:
                    # First poll - simple and friendly
                    send_chat(f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    send_chat(f"📊 Hey {player_name}! Quick question:")
                    send_chat(f"How's the AI traffic? Vote /1-/5")
                    send_chat(f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                elif milestone == 30:
                    # Second poll - show they've been here a bit
                    send_chat(f"📊 {player_name}, you've been cruising for {int(time_playing)} min!")
                    send_chat(f"   Still enjoying the traffic? /1-/5")
                elif milestone == 90:
                    # Third poll - appreciate their time
                    send_chat(f"🎉 {player_name}, 1.5 hours! Legend!")
                    send_chat(f"   Traffic still good? /1-/5 (your vote = 3x weight)")
                else:  # 180+ minutes
                    # Final poll - they're a real one
                    send_chat(f"⭐ {player_name}, 3+ hours! You're amazing!")
                    send_chat(f"   Final check: traffic quality /1-/5")
                
                # Mark this milestone as asked
                if 'polls_asked' not in session:
                    session['polls_asked'] = []
                session['polls_asked'].append(milestone)
                
                print(f"✓ Poll: Asked {player_name} for feedback (milestone: {milestone}min, session: {time_playing:.0f}min)")
                
                # Only ask one poll per check cycle to avoid spam
                break

def handle_vote_command(player_name, steam_id, message):
    """Handle /1 through /5 vote commands"""
    message = message.strip()
    
    # Check if message is a vote command
    if message in ['/1', '/2', '/3', '/4', '/5']:
        rating = int(message[1])
        
        # Check if player is in active session
        if steam_id not in active_sessions:
            print(f"⚠ Poll: Vote from unknown player {player_name}")
            return
        
        session = active_sessions[steam_id]
        join_time = session.get('join_time')
        current_time = datetime.now(timezone.utc)
        session_duration = (current_time - join_time).total_seconds() / 60  # minutes
        
        # Check if they already voted recently (prevent spam - 5 min cooldown)
        votes = session.get('votes', [])
        if votes:
            last_vote_time = votes[-1].get('time')
            if last_vote_time:
                time_since_last_vote = (current_time - last_vote_time).total_seconds() / 60
                if time_since_last_vote < 5:
                    send_chat(f"⚠️ {player_name}: Wait a bit before voting again!")
                    return
        
        # Calculate vote weight based on session duration
        # 0-30min = 1.0x, 30-60min = 2.0x, 60-90min = 2.5x, 90+ = 3.0x
        vote_weight = min(session_duration / 30.0, 3.0)
        is_regular = is_regular_player(steam_id)
        
        # Store vote in session
        vote_data = {
            'time': current_time,
            'rating': rating,
            'weight': vote_weight,
            'session_duration': session_duration
        }
        
        if 'votes' not in session:
            session['votes'] = []
        session['votes'].append(vote_data)
        
        # Save vote to file
        if save_vote(steam_id, player_name, rating, session_duration):
            # Thank you message with weight info
            weight_text = f"{vote_weight:.1f}x"
            regular_badge = " ⭐" if is_regular else ""
            vote_count = len(session['votes'])
            
            if rating >= 4:
                if vote_count > 1:
                    send_chat(f"✅ Thanks {player_name}! Still loving it! 🚗💨")
                else:
                    send_chat(f"✅ Thanks {player_name}! Glad you're enjoying the traffic! 🚗💨")
            elif rating == 3:
                send_chat(f"✅ Thanks {player_name}! We'll keep improving! 🔧")
            else:
                send_chat(f"✅ Thanks {player_name}! Your feedback helps us improve! 📊")
            
            # Show weight and session info
            if vote_count > 1:
                send_chat(f"   Vote #{vote_count}: {weight_text}{regular_badge} ({session_duration:.0f}min)")
            else:
                send_chat(f"   Vote weight: {weight_text}{regular_badge} ({session_duration:.0f}min)")
            
            print(f"✓ Poll: {player_name} voted {rating}/5 (weight: {weight_text}, session: {session_duration:.0f}min, vote #{vote_count})")
        else:
            send_chat(f"❌ {player_name}: Failed to save vote, try again!")
            print(f"✗ Poll: Failed to save vote for {player_name}")

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
            # Random join messages for variety
            join_messages = [
                f"🟢 {player_name} hit the Shuto!",
                f"🟢 {player_name} rolled into Tokyo",
                f"🟢 {player_name} entered the highway",
                f"🟢 {player_name} joined the cruise"
            ]
            import random
            embed = {
                "title": random.choice(join_messages),
                "color": 0x00ff00,
                "description": "*Waiting for session completion...*",
                "fields": [
                    {
                        "name": "🚗 Weapon of Choice",
                        "value": car if car else "Unknown",
                        "inline": True
                    }
                ],
                "footer": {
                    "text": f"Steam ID: {steam_id}" if steam_id else "RedLine Souls • Shuto Revival Project"
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
            # Random leave messages
            leave_messages = [
                f"🔴 {player_name} exited the expressway",
                f"🔴 {player_name} left the streets",
                f"🔴 {player_name} headed to the garage",
                f"🔴 {player_name} called it a night"
            ]
            import random
            embed = {
                "title": random.choice(leave_messages),
                "color": 0xff0000,
                "footer": {
                    "text": "RedLine Souls • Drive safe out there"
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
            
            # Session completion messages with personality
            if hours >= 4:
                title_emoji = "🏆"
                title_suffix = "marathon session!"
            elif hours >= 2:
                title_emoji = "⭐"
                title_suffix = "solid session"
            elif minutes >= 30:
                title_emoji = "✨"
                title_suffix = "quick cruise"
            else:
                title_emoji = "💨"
                title_suffix = "pit stop"
                
            embed = {
                "title": f"{title_emoji} {player_name}'s {title_suffix}",
                "color": 0x0099ff,
                "description": f"**Joined:** {join_ts} | **Left:** {leave_ts}",
                "fields": [
                    {
                        "name": "🚗 Car",
                        "value": car if car else "Unknown",
                        "inline": True
                    },
                    {
                        "name": "⏱️ Time on Streets",
                        "value": duration_str,
                        "inline": True
                    }
                ],
                "footer": {
                    "text": f"Steam ID: {steam_id}" if steam_id else "RedLine Souls • Thanks for cruising!"
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
            
            # Check if player had previous checksum failures
            had_failures = player_name in checksum_failures
            failure_attempts = checksum_failures.get(player_name, {}).get('attempts', 0)
            
            # Store session info
            join_time = datetime.now(timezone.utc)
            active_sessions[steam_id] = {
                'name': player_name,
                'join_time': join_time,
                'car': car_display,
                'discord_message_id': None,
                'polls_asked': [],  # Track which milestones we've asked at
                'votes': []  # Track all votes: [{time, rating, weight}]
            }
            
            # Send Discord message with failure recovery note if applicable
            if had_failures and failure_attempts > 1:
                # Player recovered from failures!
                embed = {
                    "title": f"✅ {player_name} connected successfully!",
                    "description": f"**Recovered after {failure_attempts} failed checksum attempts**",
                    "color": 0x00ff00,
                    "fields": [
                        {"name": "🚗 Car", "value": car_display if car_display else "Unknown", "inline": True},
                        {"name": "👤 Steam Profile", "value": f"[View Profile](https://steamcommunity.com/profiles/{steam_id})", "inline": True}
                    ],
                    "footer": {"text": "Files verified ✓ • Ready to cruise"},
                    "timestamp": join_time.isoformat()
                }
                try:
                    if DISCORD_WEBHOOK:
                        webhook_url = DISCORD_WEBHOOK + ('?wait=true' if '?' not in DISCORD_WEBHOOK else '&wait=true')
                        response = requests.post(webhook_url, json={"embeds": [embed]}, timeout=5)
                        if response.status_code in [200, 204]:
                            try:
                                response_data = response.json()
                                message_id = response_data.get('id')
                                if message_id:
                                    active_sessions[steam_id]['discord_message_id'] = message_id
                            except:
                                pass
                        print(f"✓ Discord: JOIN (recovered) - {player_name}")
                except Exception as e:
                    print(f"✗ Discord join error: {e}")
                del checksum_failures[player_name]
            else:
                # Normal join - DO NOT post to Discord yet, wait to see if session is meaningful
                # We'll post on disconnect if session >= 3 minutes
                # Just store the session info for now
                if player_name in checksum_failures:
                    del checksum_failures[player_name]
            
            print(f"✓ Session started: {player_name} ({steam_id})")
            
            # Send HIDDEN audio trigger if first time today
            # Format: __SPAWN_AUDIO__|steamId|playerName (matches Lua script expectation)
            if steam_id not in triggered_players:
                result = send_chat(f"__SPAWN_AUDIO__|{steam_id}|{player_name}", hidden=True)
                if result:
                    print(f"🎵 Audio trigger sent to: {player_name}")
                else:
                    print(f"✗ Failed to send audio trigger to: {player_name}")
                triggered_players.add(steam_id)
            else:
                print(f"ℹ Audio trigger skipped (already triggered today): {player_name}")
    
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
                # Calculate session duration
                join_time = session_info['join_time']
                duration_seconds = (leave_time - join_time).total_seconds()
                
                # FILTER: Only post to Discord if session >= 3 minutes (180 seconds)
                # This prevents spam from loading failures, quick checks, etc.
                MIN_SESSION_FOR_DISCORD = 180  # 3 minutes
                
                if duration_seconds >= MIN_SESSION_FOR_DISCORD:
                    # Meaningful session - post to Discord
                    message_id = session_info.get('discord_message_id')
                    
                    if message_id:
                        # We had posted a join message (e.g. for checksum recovery), edit it
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
                        # No message ID stored, post session completion message
                        send_discord_event("session_complete", player_name,
                                         steam_id=steam_id,
                                         car=session_info['car'],
                                         join_time=session_info['join_time'],
                                         leave_time=leave_time)
                    
                    print(f"✓ Session completed: {player_name} ({steam_id}) - {duration_seconds:.0f}s (posted to Discord)")
                else:
                    # Short session - skip Discord notification
                    print(f"✓ Session completed: {player_name} ({steam_id}) - {duration_seconds:.0f}s (too short, skipped Discord)")
                
                # Remove from active sessions
                del active_sessions[steam_id]
            else:
                # Fallback: player left without proper join record (server restart, etc.)
                # Only post if we don't have session info (can't check duration)
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
    
    # Chat message - Check for vote commands
    # AssettoServer format: [INF] Chat: PlayerName (steamid): message
    elif "[INF]" in line and ("Chat:" in line or "said:" in line):
        # Try multiple patterns for chat detection
        chat_match = re.search(r'Chat:\s*(.+?)\s*\((\d+)\):\s*(.+)', line)
        if not chat_match:
            chat_match = re.search(r'said:\s*(.+?)\s*\((\d+)\):\s*(.+)', line)
        
        if chat_match:
            player_name = chat_match.group(1).strip()
            steam_id = chat_match.group(2)
            message = chat_match.group(3).strip()
            
            # Handle vote commands (/1 through /5)
            if message.startswith('/') and message in ['/1', '/2', '/3', '/4', '/5']:
                handle_vote_command(player_name, steam_id, message)
    
    # Checksum failure - TRACK AND UPDATE
    elif "checksum" in line.lower() and ("fail" in line.lower() or "error" in line.lower() or "mismatch" in line.lower()):
        match = re.search(r'(\w+).*checksum', line, re.IGNORECASE)
        if match:
            player_name = match.group(1).strip()
            
            # Rate limit: only update once per 10 seconds
            event_key = f"checksum:{player_name}"
            if not should_process_event(event_key, cooldown_seconds=10):
                print(f"⚠ Checksum update suppressed for {player_name} (too soon)")
                return
            
            # Track or update checksum failures
            if player_name not in checksum_failures:
                # First failure - create new tracking entry
                checksum_failures[player_name] = {
                    'attempts': 1,
                    'message_id': None,
                    'first_attempt_time': time.time()
                }
                
                # Send initial Discord message
                embed = {
                    "title": f"⚠️ {player_name} - Checksum Failed",
                    "description": f"**Attempt 1** - Player has modified car files or outdated content",
                    "color": 0xffaa00,
                    "footer": {"text": "Player cannot join until files match server"},
                    "timestamp": datetime.now(timezone.utc).isoformat()
                }
                try:
                    if DISCORD_WEBHOOK:
                        webhook_url = DISCORD_WEBHOOK + ('?wait=true' if '?' not in DISCORD_WEBHOOK else '&wait=true')
                        response = requests.post(webhook_url, json={"embeds": [embed]}, timeout=5)
                        if response.status_code in [200, 204]:
                            try:
                                response_data = response.json()
                                message_id = response_data.get('id')
                                if message_id:
                                    checksum_failures[player_name]['message_id'] = message_id
                                    print(f"✓ Discord: CHECKSUM FAIL (Attempt 1) - {player_name} [msg:{message_id}]")
                            except:
                                print(f"✓ Discord: CHECKSUM FAIL (Attempt 1) - {player_name}")
                    else:
                        print(f"⚠ Discord events webhook not configured; skipping checksum fail for {player_name}")
                except Exception as e:
                    print(f"✗ Discord checksum error: {e}")
            else:
                # Subsequent failure - increment and edit message
                checksum_failures[player_name]['attempts'] += 1
                attempts = checksum_failures[player_name]['attempts']
                message_id = checksum_failures[player_name].get('message_id')
                
                # Edit existing message if we have message ID
                if message_id and DISCORD_WEBHOOK:
                    webhook_id, webhook_token = extract_webhook_parts(DISCORD_WEBHOOK)
                    if webhook_id and webhook_token:
                        edit_url = f"https://discord.com/api/webhooks/{webhook_id}/{webhook_token}/messages/{message_id}"
                        
                        # Escalating severity colors
                        if attempts >= 5:
                            color = 0xff0000  # Red - persistent issue
                        elif attempts >= 3:
                            color = 0xff5500  # Orange-red
                        else:
                            color = 0xffaa00  # Orange
                        
                        embed = {
                            "title": f"⚠️ {player_name} - Checksum Failed",
                            "description": f"**Attempt {attempts}** - Player has modified car files or outdated content",
                            "color": color,
                            "footer": {"text": f"First failed {int(time.time() - checksum_failures[player_name]['first_attempt_time'])}s ago • Files must match server"},
                            "timestamp": datetime.now(timezone.utc).isoformat()
                        }
                        
                        try:
                            response = requests.patch(edit_url, json={"embeds": [embed]}, timeout=5)
                            if response.status_code in [200, 204]:
                                print(f"✓ Discord: CHECKSUM FAIL (Attempt {attempts}) - {player_name} [edited]")
                            else:
                                print(f"✗ Discord edit failed ({response.status_code}): Attempt {attempts} - {player_name}")
                        except Exception as e:
                            print(f"✗ Discord checksum edit error: {e}")
                    else:
                        print(f"✓ CHECKSUM FAIL (Attempt {attempts}) - {player_name} [no webhook parts]")
                else:
                    print(f"✓ CHECKSUM FAIL (Attempt {attempts}) - {player_name}")
    
    # Player chat messages: [INF] CHAT: PlayerName (SlotID): message
    elif "CHAT:" in line and "[INF]" in line:
        match = re.search(r'\[INF\] CHAT:\s+(.+?)\s+\(\d+\):\s+(.+)', line)
        if match:
            player_name = match.group(1).strip()
            message = match.group(2).strip()
            
            # Skip CSP internal messages
            if not message.startswith('$CSP'):
                # Handle vote commands (/1 through /5)
                if message.startswith('/') and message in ['/1', '/2', '/3', '/4', '/5']:
                    # Find steam_id by player name
                    steam_id = None
                    for sid, session in active_sessions.items():
                        if session['name'] == player_name:
                            steam_id = sid
                            break
                    
                    if steam_id:
                        handle_vote_command(player_name, steam_id, message)
                    else:
                        print(f"⚠ Poll: Vote from unknown player {player_name} (not in active_sessions)")
                
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
            try:
                monitor_logs()
                # Check if any players need poll messages
                check_and_send_polls()
            except FileNotFoundError as e:
                print(f"⚠ Log file not found: {e}")
                time.sleep(5)  # Wait longer if log file missing
            except PermissionError as e:
                print(f"✗ Permission error reading logs: {e}")
                time.sleep(5)
            except Exception as e:
                print(f"✗ Error in monitor_logs: {e}")
                import traceback
                traceback.print_exc()
                time.sleep(2)  # Brief pause before retry
            
            time.sleep(CHECK_INTERVAL)
    except KeyboardInterrupt:
        print("\n\nShutting down...")
        if udp_socket:
            udp_socket.close()
    except Exception as e:
        print(f"\n✗ FATAL ERROR: {e}")
        import traceback
        traceback.print_exc()
        if udp_socket:
            udp_socket.close()
        raise  # Re-raise so systemd can restart

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

