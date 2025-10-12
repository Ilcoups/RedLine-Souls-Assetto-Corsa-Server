#!/bin/bash
# AssettoServer Startup Script

cd /home/acserver/server

# Kill any existing server instances
pkill -f AssettoServer

# Start server in background
nohup ./AssettoServer >> logs/server_console.log 2>&1 &

# Get process ID
PID=$!

echo "AssettoServer started with PID: $PID"
echo "To view logs: tail -f ~/server/logs/log-\$(date +%Y%m%d).txt"
echo "To view console: tail -f ~/server/logs/server_console.log"
echo "To stop server: pkill -f AssettoServer"
