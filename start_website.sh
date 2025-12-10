#!/bin/bash
# Start the website and status updater

# 1. Start Status Updater (Background Loop)
echo "Starting status updater..."
(while true; do
    python3 /home/acserver/server/generate_status_json.py
    sleep 10
done) > /home/acserver/server/logs/status_updater.log 2>&1 &
UPDATER_PID=$!
echo "Status updater started (PID: $UPDATER_PID)"

# 2. Start Web Server on Port 8080
echo "Starting web server on port 8080..."
cd /home/acserver/server/wwwroot
nohup python3 -m http.server 8080 > /home/acserver/server/logs/web_server.log 2>&1 &
SERVER_PID=$!
echo "Web server started (PID: $SERVER_PID)"

# Save PIDs
echo $UPDATER_PID > /home/acserver/server/website_updater.pid
echo $SERVER_PID > /home/acserver/server/website_server.pid

echo "Website is live at http://$(curl -s -4 ifconfig.me):8080"
