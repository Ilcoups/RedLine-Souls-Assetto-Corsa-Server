#!/bin/bash
# Auto-start Discord webhook scripts silently (no spam messages)

cd /home/acserver/server

# Kill any existing instances
pkill -f udp_announcer.py 2>/dev/null
pkill -f player_stats.py 2>/dev/null
sleep 1

# Start UDP announcer (chat/joins/leaves)
nohup python3 udp_announcer.py > udp_announcer.log 2>&1 &

# Start stats tracker (collisions/leaderboards)
nohup python3 player_stats.py > stats_tracker.log 2>&1 &

# Wait a moment to verify they started
sleep 2

# Check if running
UDP_PID=$(pgrep -f udp_announcer.py)
STATS_PID=$(pgrep -f player_stats.py)

if [ -n "$UDP_PID" ] && [ -n "$STATS_PID" ]; then
    echo "✓ Webhooks running (UDP: $UDP_PID, Stats: $STATS_PID)"
    exit 0
else
    echo "✗ Webhook start failed"
    exit 1
fi
