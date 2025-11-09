#!/usr/bin/env bash
# Discord & Analytics Integration Checks

section "TEST 9: Discord & Analytics Integrations"

# Check all Discord webhooks are configured
if [ -f ".env" ]; then
    if grep -q "DISCORD_WEBHOOK=" .env && [ -n "$(grep "DISCORD_WEBHOOK=" .env | cut -d'=' -f2 | tr -d '"')" ]; then
        pass "Main webhook configured (join/leave messages)"
    else
        fail "Main webhook (DISCORD_WEBHOOK) NOT configured"
    fi
    
    if grep -q "DISCORD_STATS_WEBHOOK=" .env && [ -n "$(grep "DISCORD_STATS_WEBHOOK=" .env | cut -d'=' -f2 | tr -d '"')" ]; then
        pass "Stats webhook configured (#daily-statistic)"
    else
        fail "Stats webhook (DISCORD_STATS_WEBHOOK) NOT configured"
    fi
    
    if grep -q "DISCORD_CHAT_WEBHOOK=" .env && [ -n "$(grep "DISCORD_CHAT_WEBHOOK=" .env | cut -d'=' -f2 | tr -d '"')" ]; then
        pass "Chat webhook configured (#chat-eu-1)"
    else
        fail "Chat webhook (DISCORD_CHAT_WEBHOOK) NOT configured"
    fi
    
    if grep -q "DISCORD_AUDIT_WEBHOOK=" .env && [ -n "$(grep "DISCORD_AUDIT_WEBHOOK=" .env | cut -d'=' -f2 | tr -d '"')" ]; then
        pass "Audit webhook configured (#servers)"
    else
        warn "Audit webhook (DISCORD_AUDIT_WEBHOOK) not configured (optional)"
    fi
fi

# Check PatreonAnalyticsPlugin enabled
if [ -f "cfg/extra_cfg.yml" ]; then
    if grep -q "PatreonAnalyticsPlugin" cfg/extra_cfg.yml; then
        pass "Analytics plugin enabled in config"
        
        # Check /metrics endpoint is responding
        if curl -s -f http://127.0.0.1:8081/metrics > /dev/null 2>&1; then
            pass "Analytics /metrics endpoint responding"
            
            # Check for AssettoServer-specific metrics (they exist even with 0 players)
            if curl -s http://127.0.0.1:8081/metrics 2>/dev/null | grep -q "assettoserver_client_fps"; then
                pass "Analytics metrics available"
                
                # Check if there are actually players to collect data from
                PLAYER_COUNT=$(curl -s http://127.0.0.1:8081/api/details 2>/dev/null | grep -o '"clients":[0-9]*' | grep -o '[0-9]*' || echo "0")
                if [ "$PLAYER_COUNT" -gt 0 ]; then
                    info "Analytics actively collecting from ${PLAYER_COUNT} player(s)"
                fi
            else
                warn "Analytics metrics not found (plugin may not be loaded)"
            fi
        else
            fail "Analytics /metrics endpoint NOT responding"
        fi
    else
        warn "Analytics plugin NOT enabled (optional)"
    fi
fi

# Check Hub Server Status feature configured
if [ -f "hub/configuration.yml" ]; then
    if grep -q "DiscordServerStatus:" hub/configuration.yml; then
        pass "Hub server status feature configured"
        
        # Check if server is defined
        if grep -q "redline-tokyo:" hub/configuration.yml; then
            pass "Hub server status widget 'redline-tokyo' defined"
        else
            warn "No server status widgets defined"
        fi
    else
        warn "Hub server status NOT configured (optional)"
    fi
fi

# Check player_stats.py persistence
if [ -f "player_stats.json" ]; then
    SIZE=$(du -h player_stats.json | cut -f1)
    pass "Player stats database exists (${SIZE})"
    
    # Check if it has valid JSON
    if python3 -c "import json; json.load(open('player_stats.json'))" 2>/dev/null; then
        pass "Player stats JSON is valid"
    else
        fail "Player stats JSON is CORRUPTED"
    fi
else
    warn "Player stats database not yet created (normal on first run)"
fi

# Check unified_announcer log for recent activity
if [ -f "logs/unified_announcer.log" ]; then
    LOG_SIZE=$(du -h logs/unified_announcer.log | cut -f1)
    pass "Announcer log exists (${LOG_SIZE})"
else
    warn "Announcer log not found (check journalctl)"
fi

# Check stats_tracker log
if [ -f "stats_tracker.log" ]; then
    LOG_SIZE=$(du -h stats_tracker.log | cut -f1)
    pass "Stats tracker log exists (${LOG_SIZE})"
    
    # Check if player_stats.py is running (already verified in TEST 1, but double-check)
    if pgrep -f "player_stats.py" > /dev/null 2>&1; then
        pass "Stats tracker process running"
        
        # Check for recent activity only if log is suspiciously old (>1 hour with players online)
        PLAYER_COUNT=$(curl -s http://127.0.0.1:8081/api/details 2>/dev/null | grep -o '"clients":[0-9]*' | grep -o '[0-9]*' || echo "0")
        if [ "$PLAYER_COUNT" -gt 0 ] && ! find stats_tracker.log -mmin -60 | grep -q .; then
            warn "Stats tracker not logging despite ${PLAYER_COUNT} player(s) online"
        fi
    else
        fail "Stats tracker process NOT running"
    fi
else
    warn "Stats tracker log not found (may not have started yet)"
fi

# Check traffic poll system
if grep -q "POLL_MILESTONES" unified_announcer.py 2>/dev/null; then
    pass "Traffic poll system code present (multi-milestone)"
    
    # Check milestone configuration
    MILESTONES=$(grep "POLL_MILESTONES = " unified_announcer.py | grep -o "\[.*\]" || echo "")
    if [ -n "$MILESTONES" ]; then
        pass "Poll milestones configured: $MILESTONES"
    else
        warn "Poll milestones not found"
    fi
    
    # Check if poll functions exist
    if grep -q "def check_and_send_polls" unified_announcer.py && \
       grep -q "def handle_vote_command" unified_announcer.py; then
        pass "Traffic poll functions implemented"
    else
        warn "Traffic poll functions incomplete"
    fi
    
    # Check for multiple vote support
    if grep -q "polls_asked" unified_announcer.py && \
       grep -q "votes.*\[\]" unified_announcer.py; then
        pass "Multi-vote system enabled (tracks multiple votes per session)"
    else
        warn "Multi-vote tracking not found"
    fi
    
    # Check vote cooldown
    if grep -q "time_since_last_vote" unified_announcer.py; then
        pass "Vote spam protection (5-min cooldown) implemented"
    else
        warn "Vote cooldown not implemented"
    fi
    
    # Check if player_stats has poll results display
    if grep -q "AI TRAFFIC FEEDBACK" player_stats.py 2>/dev/null; then
        pass "Traffic poll results in daily statistics"
    else
        warn "Traffic poll results not in statistics"
    fi
    
    # Check votes file (may not exist if no votes yet)
    if [ -f "traffic_votes.json" ]; then
        VOTES_SIZE=$(du -h traffic_votes.json | cut -f1)
        pass "Traffic votes file exists (${VOTES_SIZE})"
        
        # Validate JSON
        if python3 -c "import json; json.load(open('traffic_votes.json'))" 2>/dev/null; then
            pass "Traffic votes JSON is valid"
        else
            fail "Traffic votes JSON is CORRUPTED"
        fi
    else
        info "Traffic votes file not yet created (no votes)"
    fi
elif grep -q "POLL_DELAY_MINUTES" unified_announcer.py 2>/dev/null; then
    warn "Traffic poll system: OLD VERSION (single poll only)"
else
    warn "Traffic poll system not implemented"
fi

# Check Discord webhook connectivity (non-intrusive)
if [ -f ".env" ]; then
    source .env
    
    if [ -n "$DISCORD_WEBHOOK" ]; then
        # Extract webhook ID to verify it's a valid Discord webhook URL
        if echo "$DISCORD_WEBHOOK" | grep -q "discord.com/api/webhooks"; then
            pass "Main webhook URL format valid"
        else
            warn "Main webhook URL format invalid"
        fi
    fi
    
    if [ -n "$DISCORD_STATS_WEBHOOK" ]; then
        if echo "$DISCORD_STATS_WEBHOOK" | grep -q "discord.com/api/webhooks"; then
            pass "Stats webhook URL format valid"
        else
            warn "Stats webhook URL format invalid"
        fi
    fi
    
    if [ -n "$DISCORD_CHAT_WEBHOOK" ]; then
        if echo "$DISCORD_CHAT_WEBHOOK" | grep -q "discord.com/api/webhooks"; then
            pass "Chat webhook URL format valid"
        else
            warn "Chat webhook URL format invalid"
        fi
    fi
fi

