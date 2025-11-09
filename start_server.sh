#!/bin/bash
# AssettoServer Startup Script
# Unified announcer is managed by systemd (systemctl --user status unified-announcer.service)

cd /home/acserver/server

echo "🏁 Starting RedLine Souls Server..."

# Start Hub first (unless SKIP_HUB=1 is set, e.g., when called from restart_all.sh)
if [ "$SKIP_HUB" != "1" ]; then
    if [ ! -f hub/hub.pid ] || ! ps -p $(cat hub/hub.pid 2>/dev/null) > /dev/null 2>&1; then
        ./start_hub.sh
        echo "⏳ Waiting 10 seconds for Hub to initialize..."
        sleep 10
    else
        echo "✓ AssettoServer Hub already running"
    fi
else
    echo "⏭ Skipping Hub startup (SKIP_HUB=1)"
fi

sleep 1

# Kill any existing instances (CAREFULLY - don't kill Hub!)
# Use exact process name matching to avoid killing AssettoServer.Hub
if pgrep -f "^./AssettoServer$" >/dev/null 2>&1; then
    echo "Stopping existing AssettoServer..."
    pkill -f "^./AssettoServer$"
    sleep 2
fi

if pgrep -f "player_stats.py" >/dev/null 2>&1; then
    echo "Stopping player_stats..."
    pkill -f "player_stats.py"
fi

if pgrep -f "overtake_tracker" >/dev/null 2>&1; then
    pkill -f "overtake_tracker"
fi

sleep 1

# Verify Hub is still running (safety check)
if ! pgrep -f "AssettoServer.Hub" >/dev/null 2>&1; then
    echo "⚠️  WARNING: Hub is not running! Starting it..."
    ./start_hub.sh
    sleep 10
fi

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
nohup python3 -u player_stats.py > stats_tracker.log 2>&1 &
STATS_PID=$!
echo "✓ Player Stats started (PID: $STATS_PID)"

# Start overtake tracker (DISABLED - Using PatreonOvertakePlugin instead)
# nohup python3 -u overtake_tracker.py > overtake_tracker.log 2>&1 &
# OVERTAKE_PID=$!
# echo "✓ Overtake Tracker started (PID: $OVERTAKE_PID)"

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
