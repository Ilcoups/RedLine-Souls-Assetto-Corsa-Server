#!/bin/bash
# Start chat announcer alongside AssettoServer

cd /home/acserver/server

# Check if already running
if pgrep -f "chat_announcer.py" > /dev/null; then
    echo "Chat announcer already running"
    exit 0
fi

# Start the announcer
nohup python3 chat_announcer.py > chat_announcer.log 2>&1 &

echo "Chat announcer started (PID: $!)"
