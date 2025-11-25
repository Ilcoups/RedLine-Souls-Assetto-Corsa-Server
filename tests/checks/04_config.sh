#!/usr/bin/env bash
# Configuration Validation

section "TEST 4: Configuration Validation"

# Check environment file
check_file ".env" ".env file"

# Check Discord webhooks configured
if [ -f ".env" ]; then
    check_in_file "DISCORD_WEBHOOK=" ".env" "Discord webhooks configured"
fi

# Check server configs
check_file "cfg/server_cfg.ini" "Server config"
check_file "cfg/extra_cfg.yml" "Extra config"

# Verify optimizations applied
if [ -f "cfg/extra_cfg.yml" ]; then
    check_in_file "AiBehaviorUpdateIntervalHz: 60" "cfg/extra_cfg.yml" "AI Behavior refresh rate: 60 Hz ✨"
    check_in_file "OutsideNetworkBubbleRefreshRateHz: 25" "cfg/extra_cfg.yml" "Distant player refresh rate: 25 Hz ✨"
    
    # Check critical plugins enabled
    if grep -q "EnablePlugins:" cfg/extra_cfg.yml; then
        if grep -A 10 "EnablePlugins:" cfg/extra_cfg.yml | grep -q "PatreonHubPlugin"; then
            pass "Hub plugin enabled"
        else
            fail "Hub plugin NOT enabled (critical)"
        fi
        
        if grep -A 10 "EnablePlugins:" cfg/extra_cfg.yml | grep -q "RandomWeatherPlugin"; then
            pass "Weather plugin enabled"
        else
            warn "Weather plugin NOT enabled"
        fi
    fi
    
    # Check EnableClientMessages for analytics
    if grep -q "EnableClientMessages: true" cfg/extra_cfg.yml; then
        pass "Client messages enabled (required for analytics)"
    else
        warn "Client messages NOT enabled (analytics won't work)"
    fi
fi

# Check server_cfg.ini critical settings
if [ -f "cfg/server_cfg.ini" ]; then
    # Check autoclutch (critical for player experience)
    if grep -q "AUTOCLUTCH_ALLOWED=1" cfg/server_cfg.ini; then
        pass "Autoclutch enabled ✨"
    else
        warn "Autoclutch DISABLED (player experience issue)"
    fi
fi

