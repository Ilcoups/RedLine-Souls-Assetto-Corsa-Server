#!/usr/bin/env python3
"""Test RCON connection and /say command"""

import socket
import struct
import time

RCON_HOST = "127.0.0.1"
RCON_PORT = 27015
RCON_PASSWORD = "F*ckTrafficJam2025!RedLine"

def rcon_test():
    try:
        # Connect
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        sock.connect((RCON_HOST, RCON_PORT))
        print(f"✓ Connected to {RCON_HOST}:{RCON_PORT}")
        
        # Authenticate
        request_id = 1
        packet_data = struct.pack('<ii', request_id, 3)  # SERVERDATA_AUTH
        packet_data += RCON_PASSWORD.encode('utf-8') + b'\x00\x00'
        packet = struct.pack('<i', len(packet_data)) + packet_data
        sock.sendall(packet)
        print("✓ Sent auth packet")
        
        time.sleep(0.2)
        
        # Read auth response
        try:
            length_data = sock.recv(4)
            if length_data:
                length = struct.unpack('<i', length_data)[0]
                response = sock.recv(length)
                print(f"✓ Auth response: {len(response)} bytes")
        except:
            print("⚠ No auth response (may be OK)")
        
        # Test different commands
        commands = [
            "/broadcast TEST BROADCAST MESSAGE",
            "broadcast TEST WITHOUT SLASH",
            "/say TEST SAY MESSAGE"
        ]
        
        for cmd in commands:
            request_id += 1
            packet_data = struct.pack('<ii', request_id, 2)  # SERVERDATA_EXECCOMMAND
            packet_data += cmd.encode('utf-8') + b'\x00\x00'
            packet = struct.pack('<i', len(packet_data)) + packet_data
            sock.sendall(packet)
            print(f"✓ Sent command: {cmd}")
            
            time.sleep(0.2)
            try:
                length_data = sock.recv(4)
                if length_data:
                    length = struct.unpack('<i', length_data)[0]
                    response = sock.recv(length)
                    resp_body = response[8:-2].decode('utf-8', errors='ignore')
                    print(f"  Response: '{resp_body}'")
            except Exception as e:
                print(f"  Response error: {e}")
            print()
        
        sock.close()
        print("\n✅ Test complete - check in-game chat for 'TEST MESSAGE FROM RCON SCRIPT'")
        
    except Exception as e:
        print(f"✗ Error: {e}")

if __name__ == "__main__":
    rcon_test()
