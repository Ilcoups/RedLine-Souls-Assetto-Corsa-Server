#!/bin/bash
# Start AssettoServer Hub in the background

HUB_DIR="/home/acserver/server/hub"
PID_FILE="$HUB_DIR/hub.pid"
LOG_FILE="$HUB_DIR/hub.log"

cd "$HUB_DIR" || exit 1

# Check if already running
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo "❌ Hub already running (PID: $OLD_PID)"
        exit 1
    fi
fi

# Start Hub
nohup ./AssettoServer.Hub >> "$LOG_FILE" 2>&1 &
HUB_PID=$!
echo $HUB_PID > "$PID_FILE"

sleep 2

# Verify it started
if ps -p $HUB_PID > /dev/null 2>&1; then
    echo "✓ AssettoServer Hub started (PID: $HUB_PID)"
    echo "📊 Logs: tail -f $LOG_FILE"
    echo "🌐 Web Interface: http://YOUR_SERVER_IP:8000"
else
    echo "❌ Failed to start Hub"
    rm -f "$PID_FILE"
    exit 1
fi
