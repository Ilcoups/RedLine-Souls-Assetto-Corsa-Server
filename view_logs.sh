#!/bin/bash
# View AssettoServer Logs in Real-Time

echo "📋 Viewing AssettoServer logs (Ctrl+C to exit)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

tail -f logs/log-$(date +%Y%m%d).txt
