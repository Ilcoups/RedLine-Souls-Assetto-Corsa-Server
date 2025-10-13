#!/bin/bash
# Real-time connection monitor for RedLine Souls AC Server
# Shows ONLY important connection events and errors

echo "🔍 Monitoring connections on RedLine Souls AC Server..."
echo "📊 Verbose logging active - watching for disconnect reasons"
echo "⏰ Started at $(date)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

tail -f /home/acserver/server/logs/log-$(date +%Y%m%d).txt | grep --line-buffered -E "attempting to connect|has connected|has disconnected|Disconnecting|ERR|WRN|Exception|timeout|kicked|Missing|mismatch|supports extra CSP" | while read line; do
    # Color code the output
    if echo "$line" | grep -q "ERR"; then
        echo -e "\033[0;31m🔴 $line\033[0m"  # Red for errors
    elif echo "$line" | grep -q "WRN"; then
        echo -e "\033[0;33m⚠️  $line\033[0m"  # Yellow for warnings
    elif echo "$line" | grep -q "attempting to connect"; then
        echo -e "\033[0;36m🔌 $line\033[0m"  # Cyan for connection attempts
    elif echo "$line" | grep -q "has connected"; then
        echo -e "\033[0;32m✅ $line\033[0m"  # Green for successful connections
    elif echo "$line" | grep -q "Disconnecting\|has disconnected"; then
        echo -e "\033[0;35m👋 $line\033[0m"  # Magenta for disconnections
    elif echo "$line" | grep -q "supports extra CSP"; then
        echo -e "\033[0;34m📦 $line\033[0m"  # Blue for CSP features
    else
        echo "$line"
    fi
done
