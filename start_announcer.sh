#!/bin/bash
# Start full announcer (Discord + In-Game Chat)

cd /home/acserver/server

if pgrep -f "full_announcer.py" > /dev/null; then
    echo "Full announcer already running"
    exit 0
fi

nohup python3 full_announcer.py > full_announcer.log 2>&1 &
echo "Full announcer started (PID: $!)"
echo "Monitoring: Discord + In-Game Chat"
