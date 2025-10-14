#!/usr/bin/env python3
"""
Complete Connection Announcer for AssettoServer
Posts to BOTH Discord AND in-game chat
"""

import re
import time
import socket
import struct
import requests
from pathlib import Path
from datetime import datetime

# Configuration
LOG_DIR = Path("/home/acserver/server/logs")
DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1427443975425364018/8KIkIU-vjxSMEQuMhaiQ3gia-EIFMF48s_98xMTngfthM_A8eW2aDD0M_TjrfOVwJ0ah"
RCON_HOST = "127.0.0.1"
RCON_PORT = 27015
RCON_PASSWORD = "F*ckTrafficJam2025!RedLine"  # From server_cfg.ini ADMIN_PASSWORD
CHECK_INTERVAL = 0.5

# Globals
last_position = 0
last_log_file = None
rcon_socket = None

# ============================================================================
# RCON Implementation - Fixed Version
# ============================================================================

def rcon_connect():
    """Connect to RCON server"""
    global rcon_socket
    try:
        if rcon_socket:
            rcon_socket.close()
        
        rcon_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        rcon_socket.settimeout(3)
        rcon_socket.connect((RCON_HOST, RCON_PORT))
        
        # Authenticate if password is set
        if RCON_PASSWORD:
            response = rcon_send(3, RCON_PASSWORD)  # SERVERDATA_AUTH
            if response is None:
                print("✗ RCON auth failed")
                rcon_socket = None
                return False
        
        print("✓ RCON connected")
        return True
    except Exception as e:
        print(f"✗ RCON connection error: {e}")
        rcon_socket = None
        return False

def rcon_send(cmd_type, message):
    """Send RCON packet and receive response"""
    global rcon_socket
    
    if not rcon_socket:
        if not rcon_connect():
            return None
    
    try:
        # Build packet
        request_id = int(time.time() * 1000) % 10000  # Unique ID
        packet_data = struct.pack('<ii', request_id, cmd_type)
        packet_data += message.encode('utf-8') + b'\x00\x00'
        packet = struct.pack('<i', len(packet_data)) + packet_data
        
        # Send
        rcon_socket.sendall(packet)
        
        # Give server time to process
        time.sleep(0.1)
        
        # Receive response (may be multiple packets)
        try:
            length_data = rcon_socket.recv(4, socket.MSG_DONTWAIT)
            if not length_data or len(length_data) < 4:
                # Command executed but no response expected
                return ""
            
            length = struct.unpack('<i', length_data)[0]
            
            # Receive full response
            response_data = b''
            while len(response_data) < length:
                chunk = rcon_socket.recv(min(4096, length - len(response_data)))
                if not chunk:
                    break
                response_data += chunk
            
            if len(response_data) >= 8:
                resp_id, resp_type = struct.unpack('<ii', response_data[:8])
                resp_body = response_data[8:-2].decode('utf-8', errors='ignore')
                return resp_body
            else:
                return ""
        except BlockingIOError:
            # No response available - that's ok for some commands
            return ""
        
    except Exception as e:
        print(f"✗ RCON send error: {e}")
        rcon_socket = None
        return None

def send_chat(message):
    """Send chat message via RCON"""
    # Use /say command for AssettoServer (appears as "CONSOLE: message")
    result = rcon_send(2, f"/say {message}")  # SERVERDATA_EXECCOMMAND = 2
    if result is not None:
        print(f"✓ Chat: {message}")
        return True
    else:
        print(f"✗ Chat failed: {message}")
        return False

# ============================================================================
# Discord Implementation
# ============================================================================

def send_discord(message, color=0x00ff00):
    """Send message to Discord"""
    try:
        embed = {
            "embeds": [{
                "description": message,
                "color": color,
                "timestamp": datetime.now().astimezone().isoformat()
            }]
        }
        response = requests.post(DISCORD_WEBHOOK, json=embed, timeout=5)
        if response.status_code in [200, 204]:
            print(f"✓ Discord: {message}")
            return True
        else:
            print(f"✗ Discord HTTP {response.status_code}")
            return False
    except Exception as e:
        print(f"✗ Discord error: {e}")
        return False

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
            
            # Send to Discord
            send_discord(f":green_circle: **{player_name}** joined (Steam: {steam_id}, Car: {car})", 0x00ff00)
            
            # Send to in-game chat
            send_chat(f"{player_name} joined the server")
    
    # Disconnection: il has disconnected
    elif " has disconnected" in line and "[INF]" in line:
        match = re.search(r'\[INF\]\s+(.+?)\s+has disconnected', line)
        if match:
            player_name = match.group(1).strip()
            
            # Send to Discord
            send_discord(f":red_circle: **{player_name}** left the server", 0xff0000)
            
            # Send to in-game chat
            send_chat(f"{player_name} left the server")
    
    # Checksum failure
    elif "checksum" in line.lower() and ("fail" in line.lower() or "error" in line.lower()):
        match = re.search(r'(\w+).*checksum', line, re.IGNORECASE)
        if match:
            player_name = match.group(1)
            send_discord(f":warning: **{player_name}** failed checksum verification", 0xffaa00)
            send_chat(f"{player_name} failed to connect (checksum)")

# ============================================================================
# Main
# ============================================================================

def main():
    print("=" * 70)
    print("AssettoServer Complete Announcer (Discord + In-Game Chat)")
    print("=" * 70)
    print(f"RCON: {RCON_HOST}:{RCON_PORT}")
    print(f"Discord: {DISCORD_WEBHOOK[:50]}...")
    print(f"Logs: {LOG_DIR}")
    print()
    
    # Initial connection
    if rcon_connect():
        print("✓ RCON connection successful")
    else:
        print("⚠ RCON connection failed - will retry on first message")
    
    print()
    print("Monitoring for player events...")
    print()
    
    # Send startup notifications
    send_discord(":white_check_mark: Server announcer started (Discord + Chat)", 0x0099ff)
    send_chat("Player announcements active")
    
    try:
        while True:
            monitor_logs()
            time.sleep(CHECK_INTERVAL)
    except KeyboardInterrupt:
        print("\n\nShutting down...")
        send_discord(":octagonal_sign: Server announcer stopped", 0x999999)
        if rcon_socket:
            rcon_socket.close()

if __name__ == "__main__":
    main()
