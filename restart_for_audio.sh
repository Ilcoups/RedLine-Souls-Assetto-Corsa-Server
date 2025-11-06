#!/bin/bash
# RedLine Souls - Complete Server Restart
# Stops everything, restarts server + unified announcer

echo "Stopping all services..."
pkill -f AssettoServer
pkill -f unified_announcer
pkill -f spawn_audio_trigger
pkill -f udp_announcer
pkill -f full_announcer
pkill -f player_stats

sleep 3

cd /home/acserver/server

echo "Starting AssettoServer..."
nohup ./AssettoServer >> logs/server_console.log 2>&1 &
SERVER_PID=$!

echo "Starting Unified Announcer (Discord + Chat + Audio)..."
nohup python3 -u unified_announcer.py > logs/unified_announcer.log 2>&1 &
ANNOUNCER_PID=$!

echo "Starting Player Stats..."
nohup python3 player_stats.py > stats_tracker.log 2>&1 &
STATS_PID=$!

echo "Starting Audio HTTP Server (port 8082)..."
pkill -f "http.server 8082"
cd wwwroot && nohup python3 -m http.server 8082 > /dev/null 2>&1 &
HTTP_PID=$!
cd ..

sleep 2

echo ""
echo "✅ Server restarted successfully!"
echo "  AssettoServer PID: $SERVER_PID"
echo "  Unified Announcer PID: $ANNOUNCER_PID"
echo "  Player Stats PID: $STATS_PID"
echo "  Audio HTTP Server PID: $HTTP_PID (port 8082)"
echo ""
echo "Test audio: curl -I http://188.245.183.146:8082/audio/RedLineSoulsIntro.ogg"
echo ""
echo "Logs:"
echo "  Server: tail -f logs/log-\$(date +%Y%m%d).txt"
echo "  Console: tail -f logs/server_console.log"
echo "  Announcer: tail -f logs/unified_announcer.log"
echo ""
echo "Stop: pkill -f AssettoServer"

