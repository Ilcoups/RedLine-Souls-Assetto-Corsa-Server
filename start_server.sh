#!/bin/bash
# AssettoServer Startup Script
# Unified announcer is managed by systemd (systemctl --user status unified-announcer.service)

cd /home/acserver/server

echo "🏁 Starting RedLine Souls Server..."

# Kill any existing instances
pkill -f AssettoServer
pkill -f player_stats
pkill -f overtake_tracker
sleep 1

# Start server in background
nohup ./AssettoServer >> logs/server_console.log 2>&1 &
SERVER_PID=$!
echo "✓ AssettoServer started (PID: $SERVER_PID)"

# Check if unified-announcer service is running
if systemctl --user is-active --quiet unified-announcer.service; then
    echo "✓ Unified Announcer running (managed by systemd)"
else
    echo "⚠ Unified Announcer NOT running!"
    echo "  Start it with: systemctl --user start unified-announcer.service"
fi

# Start player stats
nohup python3 player_stats.py > stats_tracker.log 2>&1 &
STATS_PID=$!
echo "✓ Player Stats started (PID: $STATS_PID)"

# Start overtake tracker
nohup python3 -u overtake_tracker.py > overtake_tracker.log 2>&1 &
OVERTAKE_PID=$!
echo "✓ Overtake Tracker started (PID: $OVERTAKE_PID)"

# Start audio HTTP server if not running
if ! pgrep -f "python3 -m http.server 8082" >/dev/null 2>&1; then
    nohup python3 -m http.server 8082 --directory wwwroot --bind 0.0.0.0 > logs/audio_server.log 2>&1 &
    AUDIO_PID=$!
    echo "✓ Audio server started (PID: $AUDIO_PID)"
else
    echo "✓ Audio server already running"
fi

echo ""
echo "📊 Logs:"
echo "  Server: tail -f logs/log-\$(date +%Y%m%d).txt"
echo "  Console: tail -f logs/server_console.log"
echo "  Announcer: journalctl --user -u unified-announcer.service -f"
echo "  Stats: tail -f stats_tracker.log"
echo ""
echo "🛑 Stop: ./stop_server.sh"
