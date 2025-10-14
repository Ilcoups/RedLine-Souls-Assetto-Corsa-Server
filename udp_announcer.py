#!/usr/bin/env python3
"""
Complete Connection Announcer for AssettoServer
Posts to BOTH Discord AND in-game chat via UDP Plugin Interface
"""

import re
import time
import socket
import struct
import requests
from pathlib import Path
from datetime import datetime, timezone

# Configuration
LOG_DIR = Path("/home/acserver/server/logs")
DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1427443975425364018/8KIkIU-vjxSMEQuMhaiQ3gia-EIFMF48s_98xMTngfthM_A8eW2aDD0M_TjrfOVwJ0ah"
DISCORD_CHAT_WEBHOOK = "https://discord.com/api/webhooks/1427462778075218015/QRjTkpivsX_UgX7NhPP6-i3l4p5gPIMuYTCgqflG0Y5XF-PTpbpm0tZ_WY6lFex8jH3l"  # For all in-game chat
UDP_PLUGIN_HOST = "127.0.0.1"
UDP_PLUGIN_PORT = 12001  # Must send to UDP_PLUGIN_ADDRESS port, not LOCAL_PORT  # Default AssettoServer UDP plugin port
CHECK_INTERVAL = 0.5

# UDP Plugin Protocol Commands
ACSP_BROADCAST_CHAT = 0xCB

# Globals
last_position = 0
last_log_file = None
udp_socket = None
discord_thread_id = None  # Cache the forum thread ID

# ============================================================================
# UDP Plugin Interface - Broadcast Chat
# ============================================================================

def udp_connect():
    """Initialize UDP socket"""
    global udp_socket
    try:
        udp_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        print(f"✓ UDP socket created for {UDP_PLUGIN_HOST}:{UDP_PLUGIN_PORT}")
        return True
    except Exception as e:
        print(f"✗ UDP socket error: {e}")
        return False

def send_chat(message):
    """Send chat message via UDP Plugin Interface"""
    global udp_socket
    
    if not udp_socket:
        if not udp_connect():
            return False
    
    try:
        # Build UDP packet for broadcast chat
        # Format: [ACSP_BROADCAST_CHAT][string: message]
        packet = struct.pack('B', ACSP_BROADCAST_CHAT)
        
        # Encode message as UTF-32 string (AC format)
        message_bytes = message.encode('utf-8')
        packet += struct.pack('<I', len(message_bytes))
        packet += message_bytes
        packet += b'\x00'  # Null terminator
        
        # Send to server
        udp_socket.sendto(packet, (UDP_PLUGIN_HOST, UDP_PLUGIN_PORT))
        print(f"✓ Chat: {message}")
        return True
        
    except Exception as e:
        print(f"✗ UDP chat error: {e}")
        return False

# ============================================================================
# Discord Implementation
# ============================================================================

def send_chat_to_discord(message, player_name=None):
    """Send in-game chat message to Discord chat webhook"""
    global discord_thread_id
    
    try:
        # Skip empty messages
        if not message or not message.strip():
            return
        
        # Format the message for Discord
        if player_name:
            content = f"**{player_name}**: {message}"
        else:
            content = message
        
        # Ensure content is not too long (Discord limit is 2000 chars)
        if len(content) > 2000:
            content = content[:1997] + "..."
        
        # Simple approach - just send the message
        # Discord will figure out if it's a forum channel or regular channel
        data = {"content": content}
        response = requests.post(DISCORD_CHAT_WEBHOOK, json=data, timeout=5)
        
        if response.status_code == 200 or response.status_code == 204:
            print(f"✓ Discord Chat: {content[:100]}")
        else:
            print(f"✗ Discord Chat failed: {response.status_code} - {response.text[:200]}")
            
    except Exception as e:
        print(f"✗ Discord Chat error: {e}")

def send_discord(message_type, player_name, steam_id=None, car=None, extra_info=None):
    """Send rich embedded message to Discord webhook"""
    try:
        # Create embed based on message type
        embed = {}
        
        if message_type == "join":
            embed = {
                "title": f"🟢 {player_name} joined the server",
                "color": 0x00ff00,  # Green
                "fields": [
                    {
                        "name": "🚗 Car",
                        "value": car if car else "Unknown",
                        "inline": True
                    }
                ],
                "footer": {
                    "text": f"Steam ID: {steam_id}" if steam_id else "RedLine Souls AC Server"
                },
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
            
            if steam_id:
                embed["fields"].append({
                    "name": "👤 Steam Profile",
                    "value": f"[View Profile](https://steamcommunity.com/profiles/{steam_id})",
                    "inline": True
                })
                embed["thumbnail"] = {
                    "url": f"https://avatars.steamstatic.com/fef49e7fa7e1997310d705b2a6158ff8dc1cdfeb_full.jpg"  # Default avatar
                }
                
        elif message_type == "leave":
            embed = {
                "title": f"🔴 {player_name} left the server",
                "color": 0xff0000,  # Red
                "footer": {
                    "text": "RedLine Souls AC Server"
                },
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
            
        elif message_type == "checksum":
            embed = {
                "title": f"⚠️ {player_name} failed to connect",
                "description": "**Reason:** Checksum verification failed",
                "color": 0xffaa00,  # Orange
                "footer": {
                    "text": "Player may have modified car files"
                },
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
            
        elif message_type == "system":
            # Simple message for system announcements
            data = {"content": message_type}  # player_name contains the message
            response = requests.post(DISCORD_WEBHOOK, json=data, timeout=5)
            if response.status_code == 204:
                print(f"✓ Discord: {player_name}")
            return
        
        # Add extra info if provided
        if extra_info and message_type == "join":
            embed["fields"].append({
                "name": "ℹ️ Info",
                "value": extra_info,
                "inline": False
            })
        
        # Send embed
        data = {"embeds": [embed]}
        response = requests.post(DISCORD_WEBHOOK, json=data, timeout=5)
        
        if response.status_code == 204:
            print(f"✓ Discord: {message_type.upper()} - {player_name}")
        else:
            print(f"✗ Discord failed: {response.status_code}")
            
    except Exception as e:
        print(f"✗ Discord error: {e}")

# ============================================================================
# Log Monitoring
# ============================================================================

def get_current_log_file():
    today = datetime.now().strftime("%Y%m%d")
    return LOG_DIR / f"log-{today}.txt"

def monitor_logs():
    global last_position, last_log_file
    
    log_file = get_current_log_file()
    
    if log_file != last_log_file:
        # New log file - start from the END to avoid re-processing old entries
        last_log_file = log_file
        print(f"Monitoring: {log_file}")
        
        # Seek to end of file to only process new entries from now on
        if log_file.exists():
            with open(log_file, 'r', encoding='utf-8') as f:
                f.seek(0, 2)  # Seek to end of file (0 offset from end)
                last_position = f.tell()
                print(f"  Starting from end of file (position: {last_position})")
        else:
            last_position = 0
    
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
    
    # Connection: il (76561199185532445, 26 (ferrari_f40_s3-02_black/ADAn)) has connected
    if " has connected" in line and "[INF]" in line:
        match = re.search(r'\[INF\]\s+(.+?)\s+\((\d+),\s+\d+\s+\((.+?)\)', line)
        if match:
            player_name = match.group(1).strip()
            steam_id = match.group(2)
            car = match.group(3).split('-')[0] if '-' in match.group(3) else match.group(3)
            
            # Clean up car name (remove skin variant)
            car_display = car.split('/')[0] if '/' in car else car
            
            # Send to Discord events webhook with rich embed
            send_discord("join", player_name, steam_id=steam_id, car=car_display)
            
            # Send audio trigger to in-game chat - try multiple path formats
            send_chat("[AUDIO]/content/sfx/RedLineSoulsIntro.ogg")
            time.sleep(0.05)
            send_chat("[AUDIO]content/sfx/RedLineSoulsIntro.ogg") 
            time.sleep(0.05)
            send_chat("[AUDIO]sfx/RedLineSoulsIntro.ogg")
            time.sleep(0.1)
            send_chat(f"{player_name} joined the server")
    
    # Disconnection: il has disconnected
    elif " has disconnected" in line and "[INF]" in line:
        match = re.search(r'\[INF\]\s+(.+?)\s+has disconnected', line)
        if match:
            player_name = match.group(1).strip()
            
            # Send to Discord events webhook with rich embed
            send_discord("leave", player_name)
            
            # Send to in-game chat
            send_chat(f"{player_name} left the server")
    
    # Checksum failure
    elif "checksum" in line.lower() and ("fail" in line.lower() or "error" in line.lower()):
        match = re.search(r'(\w+).*checksum', line, re.IGNORECASE)
        if match:
            player_name = match.group(1)
            # Send to Discord events webhook
            send_discord("checksum", player_name)
            # Send to in-game chat
            send_chat(f"{player_name} failed to connect (checksum)")
    
    # Player chat messages: [INF] CHAT: PlayerName (SlotID): message
    # This is the ONLY thing that goes to the chat webhook
    elif "CHAT:" in line and "[INF]" in line:
        match = re.search(r'\[INF\] CHAT:\s+(.+?)\s+\(\d+\):\s+(.+)', line)
        if match:
            player_name = match.group(1).strip()
            message = match.group(2).strip()
            
            # Skip CSP internal messages (start with $CSP)
            if not message.startswith('$CSP'):
                # Send ONLY actual player chat to chat webhook
                send_chat_to_discord(message, player_name)

# ============================================================================
# Main
# ============================================================================

def main():
    print("=" * 70)
    print("AssettoServer Complete Announcer (Discord + In-Game Chat via UDP)")
    print("=" * 70)
    print(f"UDP Plugin: {UDP_PLUGIN_HOST}:{UDP_PLUGIN_PORT}")
    print(f"Discord Events: {DISCORD_WEBHOOK[:50]}...")
    print(f"Discord Chat: {DISCORD_CHAT_WEBHOOK[:50]}...")
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
    
    # Startup notification removed - silent start
    
    try:
        while True:
            monitor_logs()
            time.sleep(CHECK_INTERVAL)
    except KeyboardInterrupt:
        print("\n\nShutting down...")
        try:
            shutdown_embed = {
                "title": "⛔ Server Announcer Stopped",
                "color": 0x999999,
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
            requests.post(DISCORD_WEBHOOK, json={"embeds": [shutdown_embed]}, timeout=5)
        except:
            pass
        if udp_socket:
            udp_socket.close()

if __name__ == "__main__":
    main()
