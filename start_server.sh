#!/bin/bash
# AssettoServer Startup Script

cd /home/acserver/server

# Kill any existing instances
pkill -f AssettoServer
pkill -f udp_announcer.py
pkill -f player_stats.py
sleep 1

# Start server in background
nohup ./AssettoServer >> logs/server_console.log 2>&1 &
PID=$!

# Start Discord webhooks (silent - no spam messages)
nohup python3 udp_announcer.py > udp_announcer.log 2>&1 &
UDP_PID=$!
nohup python3 player_stats.py > stats_tracker.log 2>&1 &
STATS_PID=$!

echo "✓ AssettoServer started (PID: $PID)"
echo "✓ Discord webhooks started (UDP: $UDP_PID, Stats: $STATS_PID)"
echo ""
echo "Logs: tail -f ~/server/logs/log-\$(date +%Y%m%d).txt"
echo "Console: tail -f ~/server/logs/server_console.log"
echo "Stop: pkill -f AssettoServer"
