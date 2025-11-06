#!/bin/bash
# Player Stats Tracker - Startup/Management Script

SCRIPT_DIR="/home/acserver/server"
STATS_SCRIPT="player_stats.py"
PID_FILE="$SCRIPT_DIR/stats_tracker.pid"
LOG_FILE="$SCRIPT_DIR/stats_tracker.log"

case "$1" in
    start)
        if [ -f "$PID_FILE" ]; then
            PID=$(cat "$PID_FILE")
            if ps -p "$PID" > /dev/null 2>&1; then
                echo "Stats tracker already running (PID: $PID)"
                exit 1
            fi
        fi
        
        cd "$SCRIPT_DIR"
        nohup python3 "$STATS_SCRIPT" >> "$LOG_FILE" 2>&1 &
        echo $! > "$PID_FILE"
        echo "✓ Stats tracker started (PID: $(cat $PID_FILE))"
        ;;
    
    stop)
        if [ -f "$PID_FILE" ]; then
            PID=$(cat "$PID_FILE")
            if ps -p "$PID" > /dev/null 2>&1; then
                kill "$PID"
                rm "$PID_FILE"
                echo "✓ Stats tracker stopped"
            else
                echo "Stats tracker not running"
                rm "$PID_FILE"
            fi
        else
            echo "Stats tracker not running (no PID file)"
        fi
        ;;
    
    restart)
        $0 stop
        sleep 2
        $0 start
        ;;
    
    status)
        if [ -f "$PID_FILE" ]; then
            PID=$(cat "$PID_FILE")
            if ps -p "$PID" > /dev/null 2>&1; then
                echo "✓ Stats tracker running (PID: $PID)"
                echo ""
                echo "Recent activity:"
                tail -10 "$LOG_FILE"
            else
                echo "✗ Stats tracker not running (stale PID file)"
            fi
        else
            echo "✗ Stats tracker not running"
        fi
        ;;
    
    stats)
        if [ -f "$SCRIPT_DIR/player_stats.json" ]; then
            echo "Current stats summary:"
            python3 << 'EOF'
import json
with open('/home/acserver/server/player_stats.json', 'r') as f:
    data = json.load(f)
    print(f"All-time players: {len(data.get('all_time', {}))}")
    print(f"Daily players: {len(data.get('daily', {}))}")
    print(f"Last reset: {data.get('last_reset', 'Unknown')}")
EOF
        else
            echo "No stats file found"
        fi
        ;;
    
    log)
        tail -f "$LOG_FILE"
        ;;
    
    *)
        echo "Usage: $0 {start|stop|restart|status|stats|log}"
        exit 1
        ;;
esac
