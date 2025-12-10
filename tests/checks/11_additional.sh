#!/usr/bin/env bash
# Additional Infrastructure Checks - Website, Honeypot, Webhooks, Cron

section "TEST 11: Additional Infrastructure"

# ============================================================================
# WEBSITE CHECK (Port 8080)
# ============================================================================

echo ""
info "Checking website (port 8080)..."

# Check if website server is running
if pgrep -f "http.server 8080" > /dev/null 2>&1; then
    pass "Website server running (port 8080)"
    
    # Check if website is accessible
    if curl -s -f -o /dev/null -w "%{http_code}" http://127.0.0.1:8080/ 2>/dev/null | grep -q "200"; then
        pass "Website index.html accessible"
    else
        warn "Website not responding on port 8080"
    fi
else
    warn "Website server NOT running (optional - start with start_website.sh)"
fi

# Check website files exist
if [ -f "wwwroot/index.html" ]; then
    pass "Website index.html exists"
else
    warn "Website index.html missing"
fi

if [ -f "wwwroot/status.json" ]; then
    # Check if status.json is recent (updated every minute by cron)
    if find wwwroot/status.json -mmin -5 | grep -q .; then
        pass "Status JSON is fresh (updated within 5 min)"
    else
        warn "Status JSON is stale (not updated recently)"
    fi
    
    # Validate JSON
    if python3 -c "import json; json.load(open('wwwroot/status.json'))" 2>/dev/null; then
        pass "Status JSON is valid"
    else
        fail "Status JSON is CORRUPTED"
    fi
else
    warn "Status JSON not found (cron may not be running)"
fi

if [ -f "wwwroot/enhanced_stats.json" ]; then
    # Check if enhanced stats is recent (updated every 10 min by cron)
    if find wwwroot/enhanced_stats.json -mmin -15 | grep -q .; then
        pass "Enhanced stats JSON is fresh (updated within 15 min)"
    else
        warn "Enhanced stats JSON is stale (not updated recently)"
    fi
    
    # Validate JSON
    if python3 -c "import json; json.load(open('wwwroot/enhanced_stats.json'))" 2>/dev/null; then
        pass "Enhanced stats JSON is valid"
    else
        fail "Enhanced stats JSON is CORRUPTED"
    fi
else
    warn "Enhanced stats JSON not found"
fi

# ============================================================================
# HONEYPOT WEBHOOK CHECK
# ============================================================================

echo ""
info "Checking honeypot security..."

if [ -f ".env" ]; then
    # Safely source .env with defaults for optional vars
    set +u  # Temporarily allow unbound variables
    source .env
    HONEYPOT_WEBHOOK="${HONEYPOT_WEBHOOK:-}"
    set -u  # Re-enable strict mode
    
    if [ -n "$HONEYPOT_WEBHOOK" ]; then
        # Verify it's a valid Discord webhook URL
        if echo "$HONEYPOT_WEBHOOK" | grep -q "discord.com/api/webhooks"; then
            pass "Honeypot webhook configured"
            
            # Test if webhook is reachable (GET returns webhook info)
            HONEYPOT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$HONEYPOT_WEBHOOK" 2>/dev/null)
            if [ "$HONEYPOT_STATUS" = "200" ]; then
                pass "Honeypot webhook is valid and reachable"
            elif [ "$HONEYPOT_STATUS" = "404" ]; then
                fail "Honeypot webhook NOT FOUND (deleted?)"
            else
                warn "Honeypot webhook returned HTTP $HONEYPOT_STATUS"
            fi
        else
            warn "Honeypot webhook URL format invalid"
        fi
    else
        # Honeypot is optional security feature - just informational
        pass "Honeypot webhook not configured (optional security feature)"
    fi
fi

# Check honeypot log
if [ -f "logs/honeypot.log" ]; then
    LOG_SIZE=$(du -h logs/honeypot.log | cut -f1)
    pass "Honeypot log exists (${LOG_SIZE})"
    
    # Check for any alerts
    if grep -q "ALERT" logs/honeypot.log 2>/dev/null; then
        fail "⚠️  HONEYPOT ALERT DETECTED - Check logs/honeypot.log!"
    fi
else
    info "Honeypot log not yet created (will be created on first cron run)"
fi

# ============================================================================
# WEBHOOK CONNECTIVITY TESTS
# ============================================================================

echo ""
info "Testing webhook connectivity..."

if [ -f ".env" ]; then
    # Safely source .env with defaults for optional vars
    set +u  # Temporarily allow unbound variables
    source .env
    DISCORD_WEBHOOK="${DISCORD_WEBHOOK:-}"
    DISCORD_STATS_WEBHOOK="${DISCORD_STATS_WEBHOOK:-}"
    DISCORD_CHAT_WEBHOOK="${DISCORD_CHAT_WEBHOOK:-}"
    DISCORD_AUDIT_WEBHOOK="${DISCORD_AUDIT_WEBHOOK:-}"
    SPEED_TRAP_WEBHOOK="${SPEED_TRAP_WEBHOOK:-}"
    set -u  # Re-enable strict mode
    
    # Test Main Webhook
    if [ -n "$DISCORD_WEBHOOK" ]; then
        MAIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$DISCORD_WEBHOOK" 2>/dev/null)
        if [ "$MAIN_STATUS" = "200" ]; then
            pass "Main webhook reachable (HTTP 200)"
        elif [ "$MAIN_STATUS" = "404" ]; then
            fail "Main webhook NOT FOUND - check if deleted!"
        elif [ "$MAIN_STATUS" = "401" ] || [ "$MAIN_STATUS" = "403" ]; then
            fail "Main webhook UNAUTHORIZED - token invalid!"
        else
            warn "Main webhook returned HTTP $MAIN_STATUS"
        fi
    fi
    
    # Test Stats Webhook
    if [ -n "$DISCORD_STATS_WEBHOOK" ]; then
        STATS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$DISCORD_STATS_WEBHOOK" 2>/dev/null)
        if [ "$STATS_STATUS" = "200" ]; then
            pass "Stats webhook reachable (HTTP 200)"
        elif [ "$STATS_STATUS" = "404" ]; then
            fail "Stats webhook NOT FOUND - check if deleted!"
        else
            warn "Stats webhook returned HTTP $STATS_STATUS"
        fi
    fi
    
    # Test Chat Webhook
    if [ -n "$DISCORD_CHAT_WEBHOOK" ]; then
        CHAT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$DISCORD_CHAT_WEBHOOK" 2>/dev/null)
        if [ "$CHAT_STATUS" = "200" ]; then
            pass "Chat webhook reachable (HTTP 200)"
        elif [ "$CHAT_STATUS" = "404" ]; then
            fail "Chat webhook NOT FOUND - check if deleted!"
        else
            warn "Chat webhook returned HTTP $CHAT_STATUS"
        fi
    fi
    
    # Test Audit Webhook
    if [ -n "$DISCORD_AUDIT_WEBHOOK" ]; then
        AUDIT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$DISCORD_AUDIT_WEBHOOK" 2>/dev/null)
        if [ "$AUDIT_STATUS" = "200" ]; then
            pass "Audit webhook reachable (HTTP 200)"
        elif [ "$AUDIT_STATUS" = "404" ]; then
            fail "Audit webhook NOT FOUND - check if deleted!"
        else
            warn "Audit webhook returned HTTP $AUDIT_STATUS"
        fi
    fi
    
    # Test Speed Trap Webhook (via proxy) - uses DISCORD_SPEED_TRAP_WEBHOOK
    DISCORD_SPEED_TRAP_WEBHOOK="${DISCORD_SPEED_TRAP_WEBHOOK:-}"
    if [ -n "$DISCORD_SPEED_TRAP_WEBHOOK" ]; then
        if echo "$DISCORD_SPEED_TRAP_WEBHOOK" | grep -q "discord.com/api/webhooks"; then
            TRAP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$DISCORD_SPEED_TRAP_WEBHOOK" 2>/dev/null)
            if [ "$TRAP_STATUS" = "200" ]; then
                pass "Speed trap webhook reachable (HTTP 200)"
            elif [ "$TRAP_STATUS" = "404" ]; then
                fail "Speed trap webhook NOT FOUND - check if deleted!"
            else
                warn "Speed trap webhook returned HTTP $TRAP_STATUS"
            fi
        fi
    else
        fail "Speed trap webhook (DISCORD_SPEED_TRAP_WEBHOOK) not configured in .env"
    fi
fi

# ============================================================================
# CRON JOBS VERIFICATION
# ============================================================================

echo ""
info "Checking cron jobs..."

# Get cron job list
CRON_LIST=$(crontab -l 2>/dev/null || echo "")

if [ -n "$CRON_LIST" ]; then
    # Check status.json updater (every minute)
    if echo "$CRON_LIST" | grep -q "generate_status_json.py"; then
        pass "Cron: Status JSON updater configured (every minute)"
    else
        warn "Cron: Status JSON updater NOT configured"
    fi
    
    # Check log rotation (daily at 2am)
    if echo "$CRON_LIST" | grep -q "rotate_logs.sh"; then
        pass "Cron: Log rotation configured (daily)"
    else
        warn "Cron: Log rotation NOT configured"
    fi
    
    # Check speed trap daily summary (every 10 min)
    if echo "$CRON_LIST" | grep -q "speed_trap_daily_summary.py"; then
        pass "Cron: Speed trap summary configured (every 10 min)"
    else
        warn "Cron: Speed trap summary NOT configured"
    fi
    
    # Check enhanced stats (every 10 min)
    if echo "$CRON_LIST" | grep -q "generate_enhanced_stats.py"; then
        pass "Cron: Enhanced stats generator configured (every 10 min)"
    else
        warn "Cron: Enhanced stats generator NOT configured"
    fi
    
    # Count total cron jobs
    CRON_COUNT=$(echo "$CRON_LIST" | grep -c "^[^#]" || echo "0")
    info "Total cron jobs active: $CRON_COUNT"
else
    fail "No cron jobs configured!"
fi

# ============================================================================
# SPEED TRAP PROXY FUNCTIONALITY
# ============================================================================

echo ""
info "Checking speed trap proxy..."

# Check if proxy is listening
if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8083/health 2>/dev/null | grep -q "200"; then
    pass "Speed trap proxy health endpoint responding"
else
    # Proxy might not have /health, try the webhook endpoint
    if nc -z 127.0.0.1 8083 2>/dev/null; then
        pass "Speed trap proxy port 8083 is open"
    else
        warn "Speed trap proxy not responding on port 8083"
    fi
fi

# Check proxy log for errors
if [ -f "logs/speed_trap_proxy.log" ]; then
    PROXY_ERRORS=$(grep -c "ERROR\|Exception" logs/speed_trap_proxy.log 2>/dev/null | head -1 || echo "0")
    PROXY_ERRORS="${PROXY_ERRORS//[^0-9]/}"  # Remove any non-numeric chars
    PROXY_ERRORS="${PROXY_ERRORS:-0}"
    if [ "$PROXY_ERRORS" -eq 0 ] 2>/dev/null; then
        pass "Speed trap proxy log has no errors"
    else
        warn "Speed trap proxy log has $PROXY_ERRORS error(s)"
    fi
fi

# ============================================================================
# GAME SERVER API HEALTH
# ============================================================================

echo ""
info "Checking game server API..."

# Check /api/details endpoint
if curl -s -f http://127.0.0.1:8081/api/details > /dev/null 2>&1; then
    pass "Game server /api/details responding"
    
    # Get current server info
    API_DATA=$(curl -s http://127.0.0.1:8081/api/details 2>/dev/null)
    
    CLIENTS=$(echo "$API_DATA" | grep -o '"clients":[0-9]*' | grep -o '[0-9]*' || echo "0")
    MAX_CLIENTS=$(echo "$API_DATA" | grep -o '"maxClients":[0-9]*' | grep -o '[0-9]*' || echo "0")
    
    info "Current players: $CLIENTS / $MAX_CLIENTS"
else
    fail "Game server /api/details NOT responding"
fi

# Check /api/details returns valid data
API_RESPONSE=$(curl -s http://127.0.0.1:8081/api/details 2>/dev/null)
if echo "$API_RESPONSE" | grep -q '"players"'; then
    pass "Game server API returns valid player data"
else
    warn "Game server API response incomplete"
fi

# ============================================================================
# BACKUP FILES CHECK
# ============================================================================

echo ""
info "Checking backup files..."

# Check player stats backup
if [ -f "player_stats.json.bak" ]; then
    BAK_SIZE=$(du -h player_stats.json.bak | cut -f1)
    pass "Player stats backup exists (${BAK_SIZE})"
else
    info "Player stats backup not yet created"
fi

# Check traffic votes backup
if [ -f "traffic_votes.json.bak" ]; then
    BAK_SIZE=$(du -h traffic_votes.json.bak | cut -f1)
    pass "Traffic votes backup exists (${BAK_SIZE})"
else
    info "Traffic votes backup not yet created"
fi

# Check config backups
BACKUP_COUNT=$(ls -1 cfg/extra_cfg.yml.backup* 2>/dev/null | wc -l || echo "0")
if [ "$BACKUP_COUNT" -gt 0 ]; then
    pass "Config backups exist ($BACKUP_COUNT backup files)"
else
    warn "No config backups found"
fi

