#!/usr/bin/env bash
# Verification script for critical fixes applied 2025-11-07

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

pass() { echo -e "${GREEN}✅ $1${NC}"; PASS=$((PASS + 1)); }
fail() { echo -e "${RED}❌ $1${NC}"; FAIL=$((FAIL + 1)); }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  Verifying Critical Fixes Applied 2025-11-07                    ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# FIX #1: .env permissions
echo "━━━ FIX #1: .env Security ━━━"
ENV_PERMS=$(stat -c "%a" /home/acserver/server/.env 2>/dev/null || echo "000")
if [ "$ENV_PERMS" = "600" ]; then
    pass ".env permissions correct (600)"
else
    fail ".env permissions WRONG ($ENV_PERMS, should be 600)"
fi

if [ -r /home/acserver/server/.env ]; then
    pass "Owner can read .env"
else
    fail "Owner CANNOT read .env"
fi
echo ""

# FIX #2: Backup system
echo "━━━ FIX #2: Backup System ━━━"

if [ -f /home/acserver/server/backup_server.sh ] && [ -x /home/acserver/server/backup_server.sh ]; then
    pass "Backup script exists and is executable"
else
    fail "Backup script missing or not executable"
fi

if systemctl --user is-active --quiet server-backup.timer; then
    pass "Backup timer is active"
else
    fail "Backup timer is NOT active"
fi

if systemctl --user is-enabled --quiet server-backup.timer; then
    pass "Backup timer is enabled (survives reboots)"
else
    fail "Backup timer is NOT enabled"
fi

BACKUP_COUNT=$(find /home/acserver/backups -name "*.tar.gz" 2>/dev/null | wc -l)
if [ "$BACKUP_COUNT" -gt 0 ]; then
    pass "Backups exist ($BACKUP_COUNT found)"
else
    warn "No backups found (may not have run yet)"
fi

NEXT_BACKUP=$(systemctl --user list-timers --all | grep server-backup | awk '{print $1, $2, $3, $4}' || echo "Not scheduled")
if [ "$NEXT_BACKUP" != "Not scheduled" ]; then
    pass "Next backup scheduled: $NEXT_BACKUP"
else
    fail "Backup timer not scheduled"
fi
echo ""

# FIX #3: Python cache cleanup
echo "━━━ FIX #3: Python Cache ━━━"

PYC_COUNT=$(find /home/acserver/server -name "*.pyc" 2>/dev/null | wc -l)
if [ "$PYC_COUNT" -eq 0 ]; then
    pass "No .pyc files found"
else
    fail "$PYC_COUNT .pyc files still exist"
fi

PYCACHE_COUNT=$(find /home/acserver/server -name "__pycache__" -type d 2>/dev/null | wc -l)
if [ "$PYCACHE_COUNT" -eq 0 ]; then
    pass "No __pycache__ directories found"
else
    fail "$PYCACHE_COUNT __pycache__ directories still exist"
fi

if grep -q "PYTHONDONTWRITEBYTECODE" ~/.config/systemd/user/unified-announcer.service 2>/dev/null; then
    pass "unified-announcer.service has PYTHONDONTWRITEBYTECODE"
else
    fail "unified-announcer.service missing PYTHONDONTWRITEBYTECODE"
fi

if grep -q "PYTHONDONTWRITEBYTECODE" ~/.config/systemd/user/dynamic-traffic.service 2>/dev/null; then
    pass "dynamic-traffic.service has PYTHONDONTWRITEBYTECODE"
else
    fail "dynamic-traffic.service missing PYTHONDONTWRITEBYTECODE"
fi

if grep -q "__pycache__" /home/acserver/server/.gitignore 2>/dev/null; then
    pass ".gitignore includes __pycache__"
else
    warn ".gitignore may be missing __pycache__"
fi
echo ""

# FIX #4: Safe pkill
echo "━━━ FIX #4: Safe Process Management ━━━"

if grep -q 'AssettoServer\$' /home/acserver/server/start_server.sh 2>/dev/null; then
    pass "start_server.sh uses exact pattern matching"
else
    fail "start_server.sh still using unsafe pkill"
fi

if grep -q "Verify Hub is still running" /home/acserver/server/start_server.sh 2>/dev/null; then
    pass "start_server.sh has Hub safety check"
else
    fail "start_server.sh missing Hub safety check"
fi

if pgrep -f "^./AssettoServer$" >/dev/null 2>&1; then
    pass "Game server is running"
else
    warn "Game server not running (may be intentional)"
fi

if pgrep -f "AssettoServer.Hub" >/dev/null 2>&1; then
    pass "Hub is running"
else
    warn "Hub not running (may be intentional)"
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "VERIFICATION SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo ""

if [ "$FAIL" -eq 0 ]; then
    echo -e "${GREEN}✅ ALL FIXES VERIFIED SUCCESSFULLY${NC}"
    exit 0
else
    echo -e "${RED}❌ $FAIL VERIFICATION(S) FAILED${NC}"
    exit 1
fi

