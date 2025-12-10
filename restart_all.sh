#!/usr/bin/env bash
# restart_all.sh
# Graceful server restart with production readiness testing

set -euo pipefail

DRYRUN=0
SKIP_TESTS=0
FORCE_RESTART=0

for arg in "$@"; do
  case "$arg" in
    --dry-run|-n)
      DRYRUN=1
      ;;
    --skip-tests)
      SKIP_TESTS=1
      ;;
    --force|-f)
      FORCE_RESTART=1
      ;;
    --help|-h)
      echo "Usage: $0 [--dry-run] [--skip-tests] [--force]"
      echo "  --dry-run, -n     print actions without executing them"
      echo "  --skip-tests      skip production readiness tests"
      echo "  --force, -f       restart immediately without waiting for players"
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

# Pre-flight checks
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 PRE-FLIGHT CHECKS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check critical files exist
CRITICAL_FILES=("cfg/server_cfg.ini" "cfg/extra_cfg.yml" ".env" "AssettoServer" "hub/AssettoServer.Hub")
MISSING_FILES=0

for file in "${CRITICAL_FILES[@]}"; do
  if [ ! -f "$file" ] && [ ! -x "$file" ]; then
    echo "❌ CRITICAL: $file not found!"
    MISSING_FILES=$((MISSING_FILES + 1))
  fi
done

if [ $MISSING_FILES -gt 0 ]; then
  echo "❌ $MISSING_FILES critical file(s) missing - cannot restart!"
  exit 1
fi

# Check disk space
DISK_USAGE=$(df -h . | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
  echo "⚠️  WARNING: Disk usage is ${DISK_USAGE}% - consider cleanup"
fi

# Backup critical data
echo "📦 Backing up player_stats.json..."
if [ -f "player_stats.json" ]; then
  cp player_stats.json player_stats.json.bak || true
fi

if [ -f "traffic_votes.json" ]; then
  cp traffic_votes.json traffic_votes.json.bak || true
fi

echo "✅ Pre-flight checks passed"
echo ""

# ============================================================================
# PLAYER COUNT CHECK - Wait for 0 players before restart
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "👥 CHECKING FOR ACTIVE PLAYERS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

get_player_count() {
    curl -s http://127.0.0.1:8081/api/details 2>/dev/null | grep -o '"clients":[0-9]*' | grep -o '[0-9]*' || echo "0"
}

if [ "$DRYRUN" -eq 0 ]; then
    PLAYER_COUNT=$(get_player_count)
    
    if [ "$FORCE_RESTART" -eq 1 ] && [ "$PLAYER_COUNT" -gt 0 ]; then
        echo "⚠️  Found $PLAYER_COUNT player(s) online, but --force flag used"
        echo "⚠️  Proceeding with restart immediately..."
    elif [ "$PLAYER_COUNT" -gt 0 ]; then
        echo "⚠️  Found $PLAYER_COUNT player(s) online!"
        echo ""
        echo "Waiting for all players to leave before restart..."
        echo "(Press Ctrl+C to cancel and restart immediately with --force)"
        echo ""
        
        WAIT_START=$(date +%s)
        MAX_WAIT=3600  # Maximum 1 hour wait
        
        while [ "$PLAYER_COUNT" -gt 0 ]; do
            ELAPSED=$(($(date +%s) - WAIT_START))
            
            if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
                echo ""
                echo "⚠️  Maximum wait time (1 hour) exceeded!"
                echo "❓ Restart anyway? (y/n): "
                read -t 30 FORCE_RESTART || FORCE_RESTART="n"
                
                if [ "$FORCE_RESTART" != "y" ]; then
                    echo "❌ Restart cancelled"
                    exit 1
                fi
                echo "⚠️  Force restarting with $PLAYER_COUNT player(s)..."
                break
            fi
            
            # Show status every 30 seconds
            MINS=$((ELAPSED / 60))
            SECS=$((ELAPSED % 60))
            printf "\r⏳ Waiting... %d player(s) online | Time elapsed: %02d:%02d | Press Ctrl+C to cancel" "$PLAYER_COUNT" "$MINS" "$SECS"
            
            sleep 10
            PLAYER_COUNT=$(get_player_count)
        done
        
        echo ""
        echo "✅ All players have left! Proceeding with restart..."
        echo ""
    else
        echo "✅ No players online - safe to restart"
    fi
else
    echo "DRYRUN: would check player count and wait if needed"
fi

echo ""
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔄 STOPPING ALL SERVICES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "[restart_all] (dryrun=$DRYRUN) Stopping systemd services..."
run "systemctl --user stop unified-announcer.service 2>/dev/null || true"
run "systemctl --user stop dynamic-traffic.service 2>/dev/null || true"
run "systemctl --user stop speed-trap-proxy.service 2>/dev/null || true"

echo "[restart_all] (dryrun=$DRYRUN) Stopping Hub..."
run "./stop_hub.sh 2>/dev/null || true"
run "pkill -9 -f \"[A]ssettoServer.Hub\" 2>/dev/null || true"

echo "[restart_all] (dryrun=$DRYRUN) Killing stray helper processes..."
run "pkill -f \"[u]nified_announcer.py\" 2>/dev/null || true"
run "pkill -f \"[p]layer_stats.py\" 2>/dev/null || true"
run "pkill -f \"[o]vertake_tracker.py\" 2>/dev/null || true"
run "pkill -f \"[d]ynamic_traffic.py\" 2>/dev/null || true"
run "pkill -f \"[s]peed_trap_proxy.py\" 2>/dev/null || true"
run "pkill -f \"python3 -m http.server 8082\" 2>/dev/null || true"
run "pkill -9 -f \"[A]ssettoServer[^.]\" 2>/dev/null || true"

echo "[restart_all] (dryrun=$DRYRUN) Allowing graceful shutdown time..."
run "sleep 3"

echo "[restart_all] (dryrun=$DRYRUN) Verifying all processes stopped..."
if [ "$DRYRUN" -eq 0 ]; then
  if pgrep -f "AssettoServer" >/dev/null 2>&1; then
    echo "⚠ Warning: AssettoServer processes still running, force killing..."
    run "pkill -9 -f \"AssettoServer\" 2>/dev/null || true"
    run "sleep 2"
  fi
fi

echo "[restart_all] (dryrun=$DRYRUN) Running stop_server.sh (safe)..."
run "./stop_server.sh || true"

echo "[restart_all] (dryrun=$DRYRUN) Waiting for ports to be freed and system to settle..."
run "sleep 5"

echo "[restart_all] (dryrun=$DRYRUN) Starting Hub first (CRITICAL: must be ready before game server)..."
if [ "$DRYRUN" -eq 0 ]; then
  ./start_hub.sh
  
  echo "[restart_all] Waiting for Hub to fully initialize (Discord bot connection)..."
  WAIT_COUNT=0
  MAX_WAIT=30
  
  while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    if grep -q "Discord:Gateway.*Ready" hub/hub.log 2>/dev/null; then
      echo "✓ Hub Discord bot is Ready!"
      break
    fi
    
    if ! pgrep -f "AssettoServer.Hub" >/dev/null 2>&1; then
      echo "❌ ERROR: Hub crashed during startup!"
      echo "Check hub/hub.log for errors"
      exit 1
    fi
    
    sleep 1
    WAIT_COUNT=$((WAIT_COUNT + 1))
    
    if [ $((WAIT_COUNT % 5)) -eq 0 ]; then
      echo "  Waiting for Discord bot... ($WAIT_COUNT/$MAX_WAIT seconds)"
    fi
  done
  
  if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
    echo "⚠ WARNING: Hub didn't report Ready within $MAX_WAIT seconds"
    echo "Continuing anyway, but Hub might not be fully initialized"
  fi
  
  echo "[restart_all] Waiting additional 3 seconds for Hub to fully stabilize..."
  sleep 3
else
  echo "DRYRUN: would start Hub and wait for Discord Ready"
fi

echo "[restart_all] (dryrun=$DRYRUN) Starting game server and helpers..."
run "SKIP_HUB=1 ./start_server.sh"

echo "[restart_all] (dryrun=$DRYRUN) Waiting for game server to initialize..."
run "sleep 5"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔄 STARTING SYSTEMD SERVICES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Start systemd user services
SYSTEMD_SERVICES=("unified-announcer" "dynamic-traffic" "speed-trap-proxy")

for service in "${SYSTEMD_SERVICES[@]}"; do
  echo "[restart_all] Starting ${service}.service..."
  if [ "$DRYRUN" -eq 1 ]; then
    echo "DRYRUN: systemctl --user start ${service}.service"
  else
    systemctl --user start ${service}.service 2>/dev/null || true
    sleep 1
    
    if systemctl --user is-active --quiet ${service}.service 2>/dev/null; then
      echo "✅ ${service}.service: ACTIVE"
    else
      echo "⚠️  ${service}.service: NOT ACTIVE (may not be enabled)"
    fi
  fi
done
echo ""

echo "[restart_all] Verifying Hub and Server are connected..."
if [ "$DRYRUN" -eq 0 ]; then
  if grep -q "Connected to AssettoServer Hub" logs/log-$(date +%Y%m%d).txt 2>/dev/null; then
    echo "✅ Server successfully connected to Hub!"
  else
    echo "⚠ WARNING: Server might not have connected to Hub yet"
    echo "Check: tail -20 logs/log-\$(date +%Y%m%d).txt | grep Hub"
  fi
fi

echo "[restart_all] (dryrun=$DRYRUN) Allowing time for all integrations to complete..."
run "sleep 7"

echo "--- Processes ---"
if [ "$DRYRUN" -eq 1 ]; then
  echo "DRYRUN: would list processes"
else
  ps aux | egrep "AssettoServer|unified_announcer|player_stats|http.server|dynamic_traffic|speed_trap_proxy" | egrep -v egrep || true
fi

echo ""
echo ""
echo "=== BASIC VERIFICATION ==="
echo "[restart_all] Waiting additional 8 seconds for all services to fully stabilize..."
run "sleep 8"
echo "[restart_all] Running basic component checks..."

if [ "$DRYRUN" -eq 0 ]; then
  ERRORS=0
  
  # Check game server
  if pgrep -f "AssettoServer$" >/dev/null 2>&1; then
    echo "✅ Game Server: Running"
  else
    echo "❌ Game Server: NOT RUNNING"
    ERRORS=$((ERRORS + 1))
  fi
  
  # Check Hub
  if pgrep -f "AssettoServer.Hub" >/dev/null 2>&1; then
    echo "✅ Hub: Running"
  else
    echo "❌ Hub: NOT RUNNING"
    ERRORS=$((ERRORS + 1))
  fi
  
  # Check player_stats
  if pgrep -f "player_stats.py" >/dev/null 2>&1; then
    echo "✅ Player Stats: Running"
  else
    echo "❌ Player Stats: NOT RUNNING"
    ERRORS=$((ERRORS + 1))
  fi
  
  # Check audio server
  if pgrep -f "http.server 8082" >/dev/null 2>&1; then
    echo "✅ Audio Server: Running"
  else
    echo "❌ Audio Server: NOT RUNNING"
    ERRORS=$((ERRORS + 1))
  fi
  
  # Check announcer
  if systemctl --user is-active --quiet unified-announcer.service 2>/dev/null; then
    echo "✅ Unified Announcer: Running"
  else
    echo "❌ Unified Announcer: NOT RUNNING"
    ERRORS=$((ERRORS + 1))
  fi
  
  # Check dynamic traffic
  if systemctl --user is-active --quiet dynamic-traffic.service 2>/dev/null; then
    echo "✅ Dynamic Traffic: Running"
  else
    echo "⚠️  Dynamic Traffic: NOT RUNNING (optional)"
  fi
  
  # Check speed trap proxy
  if systemctl --user is-active --quiet speed-trap-proxy.service 2>/dev/null; then
    echo "✅ Speed Trap Proxy: Running"
  else
    echo "⚠️  Speed Trap Proxy: NOT RUNNING (optional)"
  fi
  
  echo ""
  if [ $ERRORS -eq 0 ]; then
    echo "✅ All services started successfully!"
  else
    echo "❌ $ERRORS service(s) failed to start!"
    echo "Check logs for details."
    exit 1
  fi
  
  # Run production readiness tests
  if [ $SKIP_TESTS -eq 0 ]; then
    echo ""
    echo ""
    echo "=== RUNNING PRODUCTION READINESS TESTS ==="
    echo "[restart_all] Waiting additional 5 seconds before comprehensive testing..."
    sleep 5
    echo ""
    
    if [ -x "tests/run_tests.sh" ]; then
      ./tests/run_tests.sh
      TEST_EXIT=$?
      
      if [ $TEST_EXIT -eq 0 ]; then
        echo ""
        echo "========================================="
        echo "🚀 SERVER IS PRODUCTION READY!"
        echo "========================================="
        exit 0
      else
        echo ""
        echo "========================================="
        echo "⚠️  PRODUCTION READINESS TESTS FAILED"
        echo "========================================="
        exit 1
      fi
    else
      echo "⚠️  WARNING: Production readiness tests not found!"
      echo "Expected: tests/run_tests.sh"
      exit 0
    fi
  else
    echo ""
    echo "⚠️  Skipping production readiness tests (--skip-tests flag)"
    exit 0
  fi
fi

exit 0
