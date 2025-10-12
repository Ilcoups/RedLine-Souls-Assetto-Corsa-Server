#!/bin/bash
# AssettoServer Status Check

if pgrep -f AssettoServer > /dev/null; then
    echo "✅ AssettoServer is RUNNING"
    echo ""
    ps aux | grep AssettoServer | grep -v grep
    echo ""
    echo "📊 Latest log entries:"
    tail -5 logs/log-$(date +%Y%m%d).txt
else
    echo "❌ AssettoServer is NOT running"
fi
