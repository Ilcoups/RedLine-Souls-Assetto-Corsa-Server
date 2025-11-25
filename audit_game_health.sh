#!/usr/bin/env bash
# Game Server Health Audit
# Audits game-specific aspects that generic system audits miss
#
# This audit focuses on:
# - Content integrity (tracks, cars, mods)
# - Database health & corruption
# - Log forensics (player-facing errors)
# - Plugin ecosystem health
# - Resource usage trends
# - Player experience metrics

set -euo pipefail

SERVER_DIR="/home/acserver/server"
cd "$SERVER_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Counters
CRITICAL=0
WARNINGS=0
INFO=0

critical() { echo -e "${RED}🔴 CRITICAL: $1${NC}"; CRITICAL=$((CRITICAL + 1)); }
warn() { echo -e "${YELLOW}⚠️  WARNING: $1${NC}"; WARNINGS=$((WARNINGS + 1)); }
info() { echo -e "${CYAN}ℹ️  INFO: $1${NC}"; INFO=$((INFO + 1)); }
pass() { echo -e "${GREEN}✅ PASS: $1${NC}"; }
section() { echo -e "\n${MAGENTA}━━━ $1 ━━━${NC}"; }

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║              🎮 GAME SERVER HEALTH AUDIT 🎮                      ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "This audit checks game-specific health that generic audits miss."
echo ""

# ===========================================================================
# SECTION 1: CONTENT INTEGRITY
# ===========================================================================
section "1. CONTENT INTEGRITY (Tracks, Cars, Mods)"

CONTENT_SIZE=$(du -sh content 2>/dev/null | cut -f1)
info "Total content size: $CONTENT_SIZE"

# Check for essential content directories
ESSENTIAL_DIRS=("content/tracks" "content/cars")
for dir in "${ESSENTIAL_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        COUNT=$(find "$dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
        if [ "$COUNT" -gt 0 ]; then
            pass "$dir exists ($COUNT items)"
        else
            warn "$dir exists but is empty"
        fi
    else
        critical "$dir is missing!"
    fi
done

# Check for track data files
if [ -f "cfg/data_track_params.ini" ]; then
    TRACK_CONFIGS=$(grep -c "^\[" cfg/data_track_params.ini 2>/dev/null || echo "0")
    info "Track configurations: $TRACK_CONFIGS"
else
    warn "cfg/data_track_params.ini not found"
fi

# Check for broken symlinks in content
BROKEN_LINKS=$(find content -xtype l 2>/dev/null | wc -l)
if [ "$BROKEN_LINKS" -gt 0 ]; then
    warn "Found $BROKEN_LINKS broken symlinks in content/"
else
    pass "No broken symlinks in content/"
fi

# Check entry_list for cars that don't exist
if [ -f "cfg/entry_list.ini" ]; then
    ENTRY_COUNT=$(grep -c "^\[CAR_" cfg/entry_list.ini 2>/dev/null || echo "0")
    info "Entry list has $ENTRY_COUNT car slots"
    
    # Extract car models and check if they exist
    MISSING_CARS=0
    while IFS= read -r car_line; do
        if [[ "$car_line" =~ ^MODEL=(.+)$ ]]; then
            CAR_MODEL="${BASH_REMATCH[1]}"
            if [ ! -d "content/cars/$CAR_MODEL" ]; then
                warn "Car model '$CAR_MODEL' in entry_list but not found in content/cars/"
                MISSING_CARS=$((MISSING_CARS + 1))
            fi
        fi
    done < <(grep "^MODEL=" cfg/entry_list.ini 2>/dev/null || true)
    
    if [ "$MISSING_CARS" -eq 0 ]; then
        pass "All cars in entry_list exist in content/"
    else
        warn "$MISSING_CARS car models referenced but missing from content/"
    fi
fi

# ===========================================================================
# SECTION 2: DATABASE HEALTH
# ===========================================================================
section "2. DATABASE HEALTH"

# Check Hub.db
if [ -f "hub/Hub.db" ]; then
    HUB_SIZE=$(du -h hub/Hub.db | cut -f1)
    info "Hub.db size: $HUB_SIZE"
    
    # Check for corruption using Python (since sqlite3 binary not available)
    if python3 -c "
import sqlite3
try:
    conn = sqlite3.connect('hub/Hub.db')
    cursor = conn.cursor()
    cursor.execute('PRAGMA integrity_check;')
    result = cursor.fetchone()[0]
    conn.close()
    exit(0 if result == 'ok' else 1)
except Exception as e:
    print(f'Error: {e}')
    exit(1)
    " 2>/dev/null; then
        pass "Hub.db integrity check passed"
    else
        critical "Hub.db integrity check FAILED - database may be corrupted!"
    fi
    
    # Check if database needs vacuuming
    DB_SIZE_BYTES=$(stat -c%s "hub/Hub.db" 2>/dev/null || echo "0")
    if [ "$DB_SIZE_BYTES" -gt 10485760 ]; then  # > 10MB
        info "Hub.db is larger than 10MB, consider running VACUUM"
    fi
else
    critical "hub/Hub.db not found!"
fi

# Check player_stats.json
if [ -f "player_stats.json" ]; then
    STATS_SIZE=$(du -h player_stats.json | cut -f1)
    info "player_stats.json size: $STATS_SIZE"
    
    # Validate JSON
    if python3 -m json.tool player_stats.json >/dev/null 2>&1; then
        pass "player_stats.json is valid JSON"
        
        # Count players
        PLAYER_COUNT=$(python3 -c "
import json
try:
    with open('player_stats.json') as f:
        data = json.load(f)
        print(len(data.get('players', [])))
except:
    print('0')
        " 2>/dev/null)
        info "Tracked players: $PLAYER_COUNT"
    else
        critical "player_stats.json is CORRUPTED (invalid JSON)!"
    fi
else
    info "player_stats.json not found (may not exist yet)"
fi

# ===========================================================================
# SECTION 3: LOG FORENSICS
# ===========================================================================
section "3. LOG FORENSICS (Player-Facing Errors)"

LOGS_SIZE=$(du -sh logs 2>/dev/null | cut -f1 || echo "0")
info "Total logs size: $LOGS_SIZE"

# Analyze recent server log for common errors
if [ -f "logs/server_console.log" ]; then
    LOG_SIZE=$(du -h logs/server_console.log | cut -f1)
    info "Server console log: $LOG_SIZE"
    
    # Check for recent errors (last 1000 lines)
    RECENT_ERRORS=$(tail -1000 logs/server_console.log 2>/dev/null | grep -ci "error" || echo "0")
    if [ "$RECENT_ERRORS" -gt 100 ]; then
        warn "High error count in recent logs: $RECENT_ERRORS errors"
    elif [ "$RECENT_ERRORS" -gt 10 ]; then
        info "Moderate error count in recent logs: $RECENT_ERRORS errors"
    else
        pass "Low error count in recent logs: $RECENT_ERRORS errors"
    fi
    
    # Check for connection failures
    CONN_FAILURES=$(tail -1000 logs/server_console.log 2>/dev/null | grep -ci "connection.*failed\|disconnect.*error\|timeout" || echo "0")
    if [ "$CONN_FAILURES" -gt 20 ]; then
        warn "High connection failure rate: $CONN_FAILURES recent failures"
    else
        info "Connection failures: $CONN_FAILURES recent events"
    fi
    
    # Check for kicks/bans
    KICKS=$(tail -1000 logs/server_console.log 2>/dev/null | grep -ci "kick\|ban" || echo "0")
    if [ "$KICKS" -gt 10 ]; then
        info "Recent kicks/bans: $KICKS events"
    fi
fi

# Check log rotation
LOG_COUNT=$(find logs -name "*.log" -type f 2>/dev/null | wc -l)
OLD_LOGS=$(find logs -name "*.log" -type f -mtime +30 2>/dev/null | wc -l)
if [ "$OLD_LOGS" -gt 10 ]; then
    warn "Found $OLD_LOGS log files older than 30 days (consider cleanup)"
else
    pass "Log retention looks good ($LOG_COUNT total logs, $OLD_LOGS old)"
fi

# ===========================================================================
# SECTION 4: PLUGIN ECOSYSTEM
# ===========================================================================
section "4. PLUGIN ECOSYSTEM"

PLUGINS_SIZE=$(du -sh plugins 2>/dev/null | cut -f1 || echo "0")
info "Total plugins size: $PLUGINS_SIZE"

# List installed plugins
if [ -d "plugins" ]; then
    PLUGIN_COUNT=$(find plugins -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
    info "Installed plugins: $PLUGIN_COUNT"
    
    # Check for plugin DLL files
    DLL_COUNT=$(find plugins -name "*.dll" -type f 2>/dev/null | wc -l)
    info "Plugin DLL files: $DLL_COUNT"
    
    # Check for Lua scripts
    LUA_COUNT=$(find plugins -name "*.lua" -type f 2>/dev/null | wc -l)
    info "Lua scripts: $LUA_COUNT"
    
    # Check for plugin configs
    CONFIG_COUNT=$(find plugins -name "*.yml" -o -name "*.yaml" -o -name "*.json" 2>/dev/null | wc -l)
    info "Plugin config files: $CONFIG_COUNT"
else
    warn "plugins/ directory not found"
fi

# Check for PatreonOvertakePlugin specifically
if [ -d "plugins/PatreonOvertakePlugin" ]; then
    pass "PatreonOvertakePlugin installed"
    
    # Check for required files
    if [ -f "plugins/PatreonOvertakePlugin/PatreonOvertakePlugin.dll" ]; then
        pass "PatreonOvertakePlugin.dll found"
    else
        critical "PatreonOvertakePlugin.dll missing!"
    fi
else
    warn "PatreonOvertakePlugin not found"
fi

# ===========================================================================
# SECTION 5: RESOURCE USAGE TRENDS
# ===========================================================================
section "5. RESOURCE USAGE TRENDS"

# Disk space
TOTAL_SPACE=$(df -h . | awk 'NR==2 {print $2}')
USED_SPACE=$(df -h . | awk 'NR==2 {print $3}')
AVAIL_SPACE=$(df -h . | awk 'NR==2 {print $4}')
USE_PERCENT=$(df -h . | awk 'NR==2 {print $5}' | tr -d '%')

info "Disk usage: $USED_SPACE / $TOTAL_SPACE ($USE_PERCENT% used, $AVAIL_SPACE available)"

if [ "$USE_PERCENT" -gt 90 ]; then
    critical "Disk usage above 90%!"
elif [ "$USE_PERCENT" -gt 80 ]; then
    warn "Disk usage above 80%"
else
    pass "Disk usage healthy"
fi

# Cache growth
CACHE_SIZE_MB=$(du -sm cache 2>/dev/null | cut -f1 || echo "0")
if [ "$CACHE_SIZE_MB" -gt 100 ]; then
    warn "Cache is large (${CACHE_SIZE_MB}MB), consider cleanup"
else
    info "Cache size: ${CACHE_SIZE_MB}MB"
fi

# Check for large log files
LARGE_LOGS=$(find logs -name "*.log" -type f -size +50M 2>/dev/null | wc -l)
if [ "$LARGE_LOGS" -gt 0 ]; then
    warn "Found $LARGE_LOGS log files larger than 50MB"
else
    pass "No oversized log files"
fi

# ===========================================================================
# SECTION 6: CONFIGURATION SANITY
# ===========================================================================
section "6. CONFIGURATION SANITY"

# Check for common misconfigurations
if [ -f "cfg/server_cfg.ini" ]; then
    # Check max clients
    MAX_CLIENTS=$(grep "^MAX_CLIENTS=" cfg/server_cfg.ini | cut -d= -f2 | tr -d ' ' || echo "0")
    if [ "$MAX_CLIENTS" -gt 0 ]; then
        info "Max clients: $MAX_CLIENTS"
        
        if [ "$MAX_CLIENTS" -gt 50 ]; then
            warn "MAX_CLIENTS > 50 may cause performance issues"
        fi
    fi
    
    # Check UDP/TCP ports
    UDP_PORT=$(grep "^UDP_PORT=" cfg/server_cfg.ini | cut -d= -f2 | tr -d ' ' || echo "0")
    TCP_PORT=$(grep "^TCP_PORT=" cfg/server_cfg.ini | cut -d= -f2 | tr -d ' ' || echo "0")
    HTTP_PORT=$(grep "^HTTP_PORT=" cfg/server_cfg.ini | cut -d= -f2 | tr -d ' ' || echo "0")
    
    info "Ports: UDP=$UDP_PORT, TCP=$TCP_PORT, HTTP=$HTTP_PORT"
    
    # Check if ports are in use
    if command -v ss >/dev/null 2>&1; then
        for port in "$UDP_PORT" "$TCP_PORT" "$HTTP_PORT"; do
            if [ "$port" != "0" ]; then
                if ss -tln | grep -q ":$port\b"; then
                    pass "Port $port is listening"
                else
                    warn "Port $port configured but NOT listening"
                fi
            fi
        done
    fi
fi

# Check extra_cfg.yml syntax
if [ -f "cfg/extra_cfg.yml" ]; then
    if python3 -c "
import yaml
try:
    with open('cfg/extra_cfg.yml') as f:
        yaml.safe_load(f)
    exit(0)
except Exception as e:
    print(f'Error: {e}')
    exit(1)
    " 2>/dev/null; then
        pass "extra_cfg.yml is valid YAML"
    else
        critical "extra_cfg.yml has SYNTAX ERRORS!"
    fi
fi

# ===========================================================================
# SECTION 7: PLAYER EXPERIENCE METRICS
# ===========================================================================
section "7. PLAYER EXPERIENCE METRICS"

# Analyze player connection patterns from recent logs
if [ -f "logs/server_console.log" ]; then
    # Count recent connections
    RECENT_CONNECTS=$(tail -2000 logs/server_console.log 2>/dev/null | grep -ci "new connection\|client connected" || echo "0")
    RECENT_DISCONNECTS=$(tail -2000 logs/server_console.log 2>/dev/null | grep -ci "client disconnected\|connection closed" || echo "0")
    
    info "Recent player activity: $RECENT_CONNECTS connects, $RECENT_DISCONNECTS disconnects"
    
    # Check for crash patterns
    CRASHES=$(tail -2000 logs/server_console.log 2>/dev/null | grep -ci "crash\|fatal\|exception" || echo "0")
    if [ "$CRASHES" -gt 5 ]; then
        warn "Detected $CRASHES potential crashes in recent logs"
    else
        pass "Low crash rate: $CRASHES events"
    fi
fi

# Check unified_announcer log for errors
if [ -f "logs/unified_announcer.log" ]; then
    ANNOUNCER_ERRORS=$(tail -500 logs/unified_announcer.log 2>/dev/null | grep -ci "error\|exception\|failed" || echo "0")
    if [ "$ANNOUNCER_ERRORS" -gt 10 ]; then
        warn "Announcer has $ANNOUNCER_ERRORS recent errors"
    else
        info "Announcer errors: $ANNOUNCER_ERRORS recent events"
    fi
fi

# ===========================================================================
# SUMMARY
# ===========================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "GAME SERVER HEALTH AUDIT SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${RED}Critical Issues: $CRITICAL${NC}"
echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
echo -e "${CYAN}Info Items: $INFO${NC}"
echo ""

if [ "$CRITICAL" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo -e "${GREEN}✅ GAME SERVER HEALTH: EXCELLENT${NC}"
    EXIT_CODE=0
elif [ "$CRITICAL" -eq 0 ]; then
    echo -e "${YELLOW}⚠️  GAME SERVER HEALTH: GOOD (with warnings)${NC}"
    EXIT_CODE=0
else
    echo -e "${RED}🔴 GAME SERVER HEALTH: NEEDS ATTENTION${NC}"
    EXIT_CODE=1
fi

echo ""
echo "Areas Audited:"
echo "  1. Content Integrity (tracks, cars, mods)"
echo "  2. Database Health (Hub.db, player_stats.json)"
echo "  3. Log Forensics (error patterns, player issues)"
echo "  4. Plugin Ecosystem (compatibility, health)"
echo "  5. Resource Usage (disk, cache, logs)"
echo "  6. Configuration Sanity (ports, YAML syntax)"
echo "  7. Player Experience (connections, crashes)"
echo ""
echo "This audit complements system audits with game-specific checks."
echo ""

exit $EXIT_CODE

