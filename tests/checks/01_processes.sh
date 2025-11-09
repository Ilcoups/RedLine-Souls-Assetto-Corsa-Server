#!/usr/bin/env bash
# Process Health Checks

section "TEST 1: Process Health Checks"

# Check Game Server
if check_process "AssettoServer$" "Game Server"; then
    GAME_PID=$(pgrep -f "AssettoServer$" | head -1)
    CPU=$(get_cpu_usage "$GAME_PID")
    MEM=$(get_mem_usage "$GAME_PID")
    
    [ -n "$CPU" ] && info "Game Server CPU: ${CPU}%"
    [ -n "$MEM" ] && info "Game Server Memory: ${MEM}%"
    
    # Warn if CPU usage is very high
    if [ -n "$CPU" ] && (( $(echo "$CPU > 90" | bc -l 2>/dev/null || echo "0") )); then
        warn "Game Server CPU usage high: ${CPU}%"
    fi
fi

# Check Hub
check_process "AssettoServer.Hub" "Hub"

# Check Player Stats
check_process "player_stats.py" "Player Stats"

# Check Audio Server
check_process "http.server 8082" "Audio Server"

# Check Announcer Service
check_systemd_service "unified-announcer.service" "Announcer Service"

# Check Dynamic Traffic Service
check_systemd_service "dynamic-traffic.service" "Dynamic Traffic Service"

# Check Speed Trap Proxy Service
check_systemd_service "speed-trap-proxy.service" "Speed Trap Proxy Service"
