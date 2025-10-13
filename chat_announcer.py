#!/usr/bin/env python3
"""
Chat Announcer for AssettoServer
Monitors server logs and broadcasts join/disconnect/checksum messages to in-game chat
"""

import re
import time
import socket
import struct
from pathlib import Path
from datetime import datetime

# Configuration
LOG_DIR = Path("/home/acserver/server/logs")
RCON_HOST = "localhost"
RCON_PORT = 27015
RCON_PASSWORD = ""  # AssettoServer doesn't require password by default
CHECK_INTERVAL = 0.5  # seconds

# Track last position in log file
last_position = 0
last_log_file = None

def get_current_log_file():
    """Get today's log file"""
    today = datetime.now().strftime("%Y%m%d")
    return LOG_DIR / f"log-{today}.txt"

class RCONClient:
    """Simple RCON client for Source RCON protocol"""
    SERVERDATA_AUTH = 3
    SERVERDATA_EXECCOMMAND = 2
    SERVERDATA_AUTH_RESPONSE = 2
    
    def __init__(self, host, port, password=""):
        self.host = host
        self.port = port
        self.password = password
        self.sock = None
        self.request_id = 0
    
    def connect(self):
        """Connect to RCON server"""
        try:
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.sock.settimeout(2)
            self.sock.connect((self.host, self.port))
            
            # Authenticate
            if self.password:
                self._send_packet(self.SERVERDATA_AUTH, self.password)
                response_type, response_data = self._recv_packet()
                if response_type != self.SERVERDATA_AUTH_RESPONSE:
                    raise Exception("RCON authentication failed")
            
            return True
        except Exception as e:
            print(f"✗ RCON connection failed: {e}")
            return False
    
    def execute(self, command):
        """Execute RCON command"""
        try:
            if not self.sock:
                if not self.connect():
                    return None
            
            self._send_packet(self.SERVERDATA_EXECCOMMAND, command)
            response_type, response_data = self._recv_packet()
            return response_data
        except Exception as e:
            print(f"✗ RCON execute failed: {e}")
            self.sock = None
            return None
    
    def _send_packet(self, packet_type, body):
        """Send RCON packet"""
        self.request_id += 1
        packet = struct.pack('<ii', self.request_id, packet_type)
        packet += body.encode('utf-8') + b'\x00\x00'
        packet = struct.pack('<i', len(packet)) + packet
        self.sock.sendall(packet)
    
    def _recv_packet(self):
        """Receive RCON packet"""
        length = struct.unpack('<i', self.sock.recv(4))[0]
        packet = self.sock.recv(length)
        request_id, response_type = struct.unpack('<ii', packet[:8])
        body = packet[8:-2].decode('utf-8', errors='ignore')
        return response_type, body
    
    def close(self):
        """Close connection"""
        if self.sock:
            self.sock.close()
            self.sock = None

# Global RCON client
rcon = None

def send_chat_message(message):
    """Send chat message via RCON"""
    global rcon
    try:
        if not rcon:
            rcon = RCONClient(RCON_HOST, RCON_PORT, RCON_PASSWORD)
        
        # Broadcast command in AssettoServer
        result = rcon.execute(f"/broadcast {message}")
        if result is not None:
            print(f"✓ Sent: {message}")
        else:
            print(f"✗ Failed to send chat")
    except Exception as e:
        print(f"✗ Error sending chat: {e}")
        rcon = None

def monitor_logs():
    """Monitor log file for join/disconnect/checksum events"""
    global last_position, last_log_file
    
    log_file = get_current_log_file()
    
    # If it's a new day, reset position
    if log_file != last_log_file:
        last_position = 0
        last_log_file = log_file
        print(f"Monitoring new log file: {log_file}")
    
    if not log_file.exists():
        return
    
    try:
        with open(log_file, 'r', encoding='utf-8') as f:
            # Seek to last position
            f.seek(last_position)
            
            # Read new lines
            new_lines = f.readlines()
            
            # Update position
            last_position = f.tell()
            
            # Process new lines
            for line in new_lines:
                process_log_line(line)
                
    except Exception as e:
        print(f"Error reading log: {e}")

def process_log_line(line):
    """Process a single log line and send chat if needed"""
    
    # Pattern: "Player Name has connected"
    # Example: [INF] Client1 has connected
    if " has connected" in line:
        match = re.search(r'\[.*?\]\s+(.+?)\s+has connected', line)
        if match:
            player_name = match.group(1).strip()
            send_chat_message(f"✓ {player_name} joined the server")
    
    # Pattern: "Player Name has disconnected"
    elif " has disconnected" in line:
        match = re.search(r'\[.*?\]\s+(.+?)\s+has disconnected', line)
        if match:
            player_name = match.group(1).strip()
            send_chat_message(f"✗ {player_name} left the server")
    
    # Pattern: Checksum failed
    elif "checksum" in line.lower() and "fail" in line.lower():
        match = re.search(r'\[.*?\]\s+(.+?)\s+.*checksum.*fail', line, re.IGNORECASE)
        if match:
            player_name = match.group(1).strip()
            send_chat_message(f"⚠ {player_name} failed checksum verification")

def main():
    """Main loop"""
    global rcon
    
    print("=" * 60)
    print("AssettoServer Chat Announcer Started")
    print("=" * 60)
    print(f"Log directory: {LOG_DIR}")
    print(f"RCON: {RCON_HOST}:{RCON_PORT}")
    print(f"Check interval: {CHECK_INTERVAL}s")
    print()
    print("Monitoring for player join/disconnect/checksum events...")
    print()
    
    try:
        while True:
            try:
                monitor_logs()
                time.sleep(CHECK_INTERVAL)
            except KeyboardInterrupt:
                print("\nShutting down...")
                break
            except Exception as e:
                print(f"Error in main loop: {e}")
                time.sleep(5)
    finally:
        if rcon:
            rcon.close()

if __name__ == "__main__":
    main()
