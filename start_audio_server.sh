#!/bin/bash
# Start HTTP server for spawn audio file
cd /home/acserver/server/wwwroot
pkill -f "http.server 8082"
nohup python3 -m http.server 8082 > /dev/null 2>&1 &
echo "Audio HTTP server started on port 8082"
echo "Test: curl -I http://localhost:8082/audio/RedLineSoulsIntro.ogg"

