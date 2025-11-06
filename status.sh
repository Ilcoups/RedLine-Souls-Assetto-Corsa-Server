#!/usr/bin/env bash
# status.sh - quick server health and AI-relevant info

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$BASE_DIR"

echo "=== Process snapshot ==="
ps aux | egrep "AssettoServer|unified_announcer|player_stats|http.server" | egrep -v egrep || true

echo "\n=== Listening ports (TCP) ==="
ss -lntp 2>/dev/null | egrep "LISTEN|127.0.0.1|0.0.0.0" || true

echo "\n=== Listening ports (UDP) ==="
ss -lunp 2>/dev/null | egrep "127.0.0.1|0.0.0.0|9600|12000" || true

echo "\n=== Recent server console (last 80 lines) ==="
tail -n 80 logs/server_console.log || true

echo "\n=== Recent AI-related events (last 200 lines from today's log matching spawn/collision) ==="
grep -Ei "spawn|spawned|despawn|collision|collided|Ai|AI" logs/log-$(date +%Y%m%d).txt 2>/dev/null | tail -n 200 || echo "(no matches)"

echo "\n=== Audio HTTP server check ==="
if pgrep -f "python3 -m http.server 8082" >/dev/null 2>&1; then
  echo "Audio server running on port 8082"
else
  echo "Audio server NOT running"
fi

exit 0
