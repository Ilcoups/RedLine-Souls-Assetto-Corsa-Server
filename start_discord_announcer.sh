#!/bin/bash
cd /home/acserver/server
if pgrep -f "discord_announcer.py" > /dev/null; then
    echo "Discord announcer already running"
    exit 0
fi
nohup python3 discord_announcer.py > discord_announcer.log 2>&1 &
echo "Discord announcer started (PID: $!)"
