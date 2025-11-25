#!/usr/bin/env python3
"""Create simple HTTP endpoint for Lua to query personal best from correct overtake_N table"""

import json
import sqlite3
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import parse_qs, urlparse

HUB_DB = "/home/acserver/server/hub/Hub.db"

class OvertakePBHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urlparse(self.path)
        
        if parsed.path == "/overtake-pb":
            # Parse query params
            params = parse_qs(parsed.query)
            steam_id = params.get('steamId', [None])[0]
            
            if not steam_id:
                self.send_error(400, "Missing steamId parameter")
                return
            
            try:
                conn = sqlite3.connect(HUB_DB)
                c = conn.cursor()
                
                # Query correct overtake_N table
                c.execute("""
                    SELECT e.score, p.name
                    FROM overtake_n_leaderboard_entries e
                    JOIN players p ON e.player_id = p.player_id
                    WHERE p.player_id = ? AND e.overtake_n_leaderboard_id = 1
                    ORDER BY e.score DESC LIMIT 1
                """, (steam_id,))
                
                result = c.fetchone()
                
                if result:
                    score, name = result
                    
                    # Get rank
                    c.execute("""
                        SELECT COUNT(*) + 1
                        FROM overtake_n_leaderboard_entries
                        WHERE score > ? AND overtake_n_leaderboard_id = 1
                    """, (score,))
                    rank = c.fetchone()[0]
                    
                    response = {
                        "steamId": steam_id,
                        "name": name,
                        "score": score,
                        "rank": rank
                    }
                else:
                    response = {
                        "steamId": steam_id,
                        "score": 0,
                        "rank": 0
                    }
                
                conn.close()
                
                # Send JSON response
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(json.dumps(response).encode())
                
            except Exception as e:
                self.send_error(500, f"Database error: {e}")
        else:
            self.send_error(404)
    
    def log_message(self, format, *args):
        # Suppress default logging
        pass

if __name__ == "__main__":
    server = HTTPServer(('127.0.0.1', 8085), OvertakePBHandler)
    print("Overtake PB API listening on http://127.0.0.1:8085")
    print("Usage: GET /overtake-pb?steamId=76561199185532445")
    server.serve_forever()
