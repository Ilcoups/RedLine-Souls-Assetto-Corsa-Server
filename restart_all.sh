#!/usr/bin/env bash
# restart_all.sh
# One-shot stop/start wrapper that ensures a single announcer and helper processes

set -euo pipefail

DRYRUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run|-n)
      DRYRUN=1
      ;;
    --help|-h)
      echo "Usage: $0 [--dry-run]"
      echo "  --dry-run, -n   print actions without executing them"
      exit 0
      ;;
  esac
done

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$BASE_DIR"

run() {
  if [ "$DRYRUN" -eq 1 ]; then
    echo "DRYRUN: $*"
  else
    eval "$@"
  fi
}

echo "[restart_all] (dryrun=$DRYRUN) Stopping systemd user unit (if active) to avoid duplicates..."
run "systemctl --user stop unified-announcer.service 2>/dev/null || true"

echo "[restart_all] (dryrun=$DRYRUN) Killing stray helper processes (announcer, player_stats, http server, AssettoServer)..."
run "pkill -f \"[u]nified_announcer.py\" 2>/dev/null || true"
run "pkill -f \"[p]layer_stats.py\" 2>/dev/null || true"
run "pkill -f \"python3 -m http.server 8082\" 2>/dev/null || true"
run "pkill -f \"[A]ssettoServer\" 2>/dev/null || true"

run "sleep 1"

echo "[restart_all] (dryrun=$DRYRUN) Running stop_server.sh (safe)..."
run "./stop_server.sh || true"

echo "[restart_all] (dryrun=$DRYRUN) Waiting a moment to let processes exit..."
run "sleep 2"

echo "[restart_all] (dryrun=$DRYRUN) Starting server and helpers (start_server.sh)..."
run "./start_server.sh"

echo "[restart_all] (dryrun=$DRYRUN) Waiting for processes to settle..."
run "sleep 3"

echo "--- Processes ---"
if [ "$DRYRUN" -eq 1 ]; then
  echo "DRYRUN: would list processes"
else
  ps aux | egrep "AssettoServer|unified_announcer|player_stats|http.server" | egrep -v egrep || true
fi

echo "--- unified-announcer.service active? ---"
if [ "$DRYRUN" -eq 1 ]; then
  echo "DRYRUN: would check systemctl --user is-active unified-announcer.service"
else
  if systemctl --user is-active --quiet unified-announcer.service 2>/dev/null; then
    echo "unified-announcer.service: active"
  else
    echo "unified-announcer.service: inactive (start script launched announcer)"
  fi
fi

echo "[restart_all] Restart complete. If you prefer systemd to manage the announcer, disable its launch in start_server.sh and enable the user unit:"
echo "    systemctl --user enable --now unified-announcer.service"

exit 0
