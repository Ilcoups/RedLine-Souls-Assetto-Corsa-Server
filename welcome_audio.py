#!/usr/bin/env python3
"""
Welcome audio player via UDP chat command
Sends audio tag in chat when player joins
"""

import socket
import struct
import time

UDP_IP = "127.0.0.1"
UDP_PORT = 12000

def send_chat_message(message):
    """Send chat message via UDP plugin interface"""
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    
    # AC UDP protocol for broadcast chat
    # Message type 57 = Broadcast Chat
    packet = struct.pack('B', 57)  # Message type
    packet += message.encode('utf-8')
    
    sock.sendto(packet, (UDP_IP, UDP_PORT))
    sock.close()

def main():
    """Monitor for new connections and play welcome audio"""
    import re
    import os
    from datetime import datetime
    
    played_for = set()  # Track who we've played audio for
    log_file_path = f"/home/acserver/server/logs/log-{datetime.now().strftime('%Y%m%d')}.txt"
    last_position = 0
    
    print("Welcome audio monitor started...")
    
    while True:
        try:
            if not os.path.exists(log_file_path):
                time.sleep(1)
                continue
            
            with open(log_file_path, 'r', encoding='utf-8', errors='ignore') as f:
                f.seek(last_position)
                new_lines = f.readlines()
                last_position = f.tell()
            
            for line in new_lines:
                # Check for player connection
                match = re.search(r'\[INF\]\s+([\w\s\-_]+?)\s+\((\d{17}),.*?\)\s+has connected', line)
                if match:
                    player_name = match.group(1)
                    steam_id = match.group(2)
                    
                    if steam_id not in played_for:
                        print(f"Playing welcome audio for {player_name}")
                        # Send audio in chat after 3 second delay
                        time.sleep(3)
                        send_chat_message("/audio content/sfx/RedLineSoulsIntro.ogg")
                        played_for.add(steam_id)
            
            time.sleep(0.5)
            
        except Exception as e:
            print(f"Error: {e}")
            time.sleep(1)

if __name__ == "__main__":
    main()
