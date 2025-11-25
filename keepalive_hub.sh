#!/bin/bash
# Keepalive script for AssettoServer Hub
# Hub crashes every 2-3 minutes but game server auto-reconnects
# Just keep Hub alive, don't touch the game server!

HUB_DIR="/home/acserver/server/hub"
LOG_FILE="$HUB_DIR/hub.log"
KEEPALIVE_LOG="$HUB_DIR/keepalive.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Hub keepalive started (game server auto-reconnects)" >> "$KEEPALIVE_LOG"

while true; do
    # Check if Hub is running
    if ! pgrep -f "AssettoServer.Hub" > /dev/null; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Hub crashed, restarting..." >> "$KEEPALIVE_LOG"
        
        # Restart Hub ONLY (game server will auto-reconnect)
        cd "$HUB_DIR" || exit 1
        nohup ./AssettoServer.Hub >> "$LOG_FILE" 2>&1 &
        
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Hub restarted (PID: $!)" >> "$KEEPALIVE_LOG"
        
        # Wait before next check
        sleep 5
    fi
    
    # Check every 3 seconds (Hub crashes every 2-3 min)
    sleep 3
done
