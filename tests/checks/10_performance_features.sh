#!/usr/bin/env bash
# Test Module: Performance Features
# Tests: Load monitoring, speed trap proxy, dynamic traffic scaling

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 10: Performance Features"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ============================================================================
# Dynamic Traffic Load Monitoring
# ============================================================================

# Check if load monitoring is enabled
if grep -q "LOAD_CONFIG" dynamic_traffic.py 2>/dev/null; then
    pass "Dynamic traffic load monitoring code present"
    
    # Check load monitoring functions
    if grep -q "def monitor_server_load" dynamic_traffic.py && \
       grep -q "def get_cpu_usage" dynamic_traffic.py && \
       grep -q "def get_memory_usage" dynamic_traffic.py; then
        pass "Load monitoring functions implemented"
    else
        warn "Load monitoring functions incomplete"
    fi
    
    # Check emergency scaling
    if grep -q "def apply_emergency_scaling" dynamic_traffic.py && \
       grep -q "def restore_normal_traffic" dynamic_traffic.py; then
        pass "Emergency traffic scaling implemented"
    else
        warn "Emergency scaling not found"
    fi
    
    # Check player spike detection
    if grep -q "def detect_player_spike" dynamic_traffic.py; then
        pass "Player spike detection implemented"
    else
        warn "Player spike detection not found"
    fi
    
    # Verify dynamic-traffic service is running
    if systemctl --user is-active --quiet dynamic-traffic.service 2>/dev/null; then
        pass "Dynamic traffic service running"
        
        # Check if it's running with --monitor flag
        if ps aux | grep -q "[d]ynamic_traffic.py --monitor"; then
            pass "Load monitoring active (--monitor flag)"
        else
            warn "Dynamic traffic running without monitoring"
        fi
    else
        warn "Dynamic traffic service NOT running"
    fi
    
    # Check logs for monitoring activity
    if [ -f "logs/dynamic_traffic.log" ]; then
        if grep -q "Server Status:" logs/dynamic_traffic.log 2>/dev/null; then
            pass "Load monitoring logs found"
            
            # Get latest status
            LATEST_STATUS=$(grep "Server Status:" logs/dynamic_traffic.log | tail -1)
            if echo "$LATEST_STATUS" | grep -q "NORMAL"; then
                pass "Server load: NORMAL (latest check)"
            elif echo "$LATEST_STATUS" | grep -q "WARNING"; then
                warn "Server load: WARNING (check CPU/memory)"
            elif echo "$LATEST_STATUS" | grep -q "CRITICAL"; then
                fail "Server load: CRITICAL (emergency scaling active)"
            fi
        else
            info "No load monitoring logs yet (may be too recent)"
        fi
    else
        warn "Dynamic traffic log file not found"
    fi
else
    warn "Load monitoring not implemented"
fi

# ============================================================================
# Speed Trap Webhook Proxy
# ============================================================================

# Check if speed trap proxy exists
if [ -f "speed_trap_proxy.py" ]; then
    pass "Speed trap proxy script exists"
    
    # Check proxy service
    if systemctl --user is-active --quiet speed-trap-proxy.service 2>/dev/null; then
        pass "Speed trap proxy service running"
        
        # Check if listening on port 8083
        if lsof -i:8083 2>/dev/null | grep -q LISTEN; then
            pass "Speed trap proxy listening on port 8083"
        else
            warn "Speed trap proxy NOT listening on port 8083"
        fi
        
        # Check configuration (now uses .env instead of conf file)
        if grep -q "DISCORD_SPEED_TRAP_WEBHOOK" .env 2>/dev/null; then
            pass "Speed trap webhook configured in .env"
        elif [ -f "speed_trap_proxy.conf" ]; then
            pass "Speed trap proxy configuration exists (legacy conf)"
        else
            warn "Speed trap webhook not configured in .env"
        fi
    else
        warn "Speed trap proxy service NOT running"
    fi
    
    # Check if extra_cfg.yml points to proxy
    if grep -q "127.0.0.1:8083" cfg/extra_cfg.yml 2>/dev/null; then
        pass "Speed trap configured to use local proxy"
    else
        warn "Speed trap not configured to use proxy (direct Discord upload)"
    fi
    
    # Check proxy queue implementation
    if grep -q "Queue" speed_trap_proxy.py && \
       grep -q "webhook_worker" speed_trap_proxy.py; then
        pass "Async webhook queue implemented"
    else
        warn "Webhook queue not found in proxy"
    fi
else
    warn "Speed trap proxy not implemented"
fi

# ============================================================================
# Systemd Service Integration
# ============================================================================

echo ""
info "Checking systemd service files..."

# Check if service files exist
SERVICES=("unified-announcer" "dynamic-traffic" "speed-trap-proxy")
for service in "${SERVICES[@]}"; do
    SERVICE_FILE="$HOME/.config/systemd/user/${service}.service"
    if [ -f "$SERVICE_FILE" ]; then
        pass "Service file exists: ${service}.service"
        
        # Check if enabled
        if systemctl --user is-enabled --quiet "${service}.service" 2>/dev/null; then
            pass "Service enabled: ${service}.service"
        else
            warn "Service NOT enabled: ${service}.service"
        fi
    else
        warn "Service file missing: ${service}.service"
    fi
done

# ============================================================================
# Performance Monitoring Stats
# ============================================================================

echo ""
info "Performance statistics:"

# Get current system load
if command -v uptime &>/dev/null; then
    LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | xargs)
    info "System load average: $LOAD_AVG"
fi

# Get memory usage
if [ -f /proc/meminfo ]; then
    TOTAL_MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    FREE_MEM=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    USED_PERCENT=$(( (TOTAL_MEM - FREE_MEM) * 100 / TOTAL_MEM ))
    info "Memory usage: ${USED_PERCENT}% ($(( (TOTAL_MEM - FREE_MEM) / 1024 ))MB used)"
fi

# Check AssettoServer CPU usage
if pgrep -f "AssettoServer[^.]" >/dev/null 2>&1; then
    CPU_USAGE=$(ps aux | grep "[A]ssettoServer[^.]" | awk '{print $3}')
    info "AssettoServer CPU: ${CPU_USAGE}%"
fi
