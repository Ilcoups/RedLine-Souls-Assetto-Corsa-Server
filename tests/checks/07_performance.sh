#!/usr/bin/env bash
# System Performance Checks

section "TEST 7: System Performance"

# Check system load
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
info "System load average: ${LOAD_AVG}"

# Check available memory
FREE_MEM=$(free -h | awk '/^Mem:/ {print $7}')
info "Free memory: ${FREE_MEM}"

# Check for zombie processes
ZOMBIE_COUNT=$(ps aux | { grep -c '<defunct>' || true; })
if [ "$ZOMBIE_COUNT" -eq 0 ]; then
    pass "No zombie processes"
else
    # 1-2 zombies from grep itself is normal
    if [ "$ZOMBIE_COUNT" -le 2 ]; then
        info "Found ${ZOMBIE_COUNT} zombie process(es) (likely from grep, normal)"
    else
        warn "Found ${ZOMBIE_COUNT} zombie processes"
    fi
fi

