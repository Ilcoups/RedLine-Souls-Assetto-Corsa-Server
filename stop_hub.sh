#!/bin/bash
# Stop AssettoServer Hub

HUB_DIR="/home/acserver/server/hub"
PID_FILE="$HUB_DIR/hub.pid"

if [ ! -f "$PID_FILE" ]; then
    echo "No Hub PID file found"
    # Try to find and kill it anyway
    PIDS=$(pgrep -f "AssettoServer.Hub")
    if [ -n "$PIDS" ]; then
        echo "Found Hub process(es), stopping..."
        kill $PIDS 2>/dev/null
        sleep 1
        kill -9 $PIDS 2>/dev/null
        echo "✓ AssettoServer Hub stopped"
    else
        echo "No Hub process found"
    fi
    exit 0
fi

HUB_PID=$(cat "$PID_FILE")

if ps -p "$HUB_PID" > /dev/null 2>&1; then
    kill "$HUB_PID" 2>/dev/null
    sleep 1
    
    # Force kill if still running
    if ps -p "$HUB_PID" > /dev/null 2>&1; then
        kill -9 "$HUB_PID" 2>/dev/null
    fi
    
    rm -f "$PID_FILE"
    echo "✓ AssettoServer Hub stopped"
else
    echo "Hub not running (stale PID file)"
    rm -f "$PID_FILE"
fi
