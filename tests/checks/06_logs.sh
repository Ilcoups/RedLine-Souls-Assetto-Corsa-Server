#!/usr/bin/env bash
# Log Health Analysis

section "TEST 6: Log Health Analysis"

TODAY_LOG="logs/log-$(date +%Y%m%d).txt"

if [ -f "$TODAY_LOG" ]; then
    # Get server start time from log
    SERVER_START=$(grep -m1 "AssettoServer 0.0" "$TODAY_LOG" 2>/dev/null | grep -oE "^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}" | tail -1)
    
    # Check for REAL errors (exclude startup transient errors)
    # Startup errors: NullReference during initialization, connection timeouts during startup
    # We only care about errors that happen 2+ minutes after server start
    if [ -n "$SERVER_START" ]; then
        # Convert to timestamp for comparison
        START_TS=$(date -d "$SERVER_START" +%s 2>/dev/null || echo "0")
        GRACE_PERIOD=$((START_TS + 120))  # 2 minute grace period after start
        
        # Count errors outside grace period
        ERROR_COUNT=0
        while IFS= read -r line; do
            ERROR_TIME=$(echo "$line" | grep -oE "^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}" || echo "")
            if [ -n "$ERROR_TIME" ]; then
                ERROR_TS=$(date -d "$ERROR_TIME" +%s 2>/dev/null || echo "0")
                if [ "$ERROR_TS" -gt "$GRACE_PERIOD" ]; then
                    ERROR_COUNT=$((ERROR_COUNT + 1))
                fi
            fi
        done < <(grep "\[ERR\]" "$TODAY_LOG" 2>/dev/null | tail -100)
        
        if [ "$ERROR_COUNT" -eq 0 ]; then
            pass "No runtime errors in recent logs (startup errors excluded)"
        else
            warn "Found ${ERROR_COUNT} runtime errors in recent logs"
        fi
    else
        # Fallback to simple count
        ERROR_COUNT=$(count_log_errors "$TODAY_LOG" 100 "\[ERR\]")
        if [ "$ERROR_COUNT" -eq 0 ]; then
            pass "No errors in recent logs"
        else
            warn "Found ${ERROR_COUNT} errors in recent logs"
        fi
    fi
    
    # Check for warnings (less strict)
    WARN_COUNT=$(count_log_errors "$TODAY_LOG" 100 "\[WRN\]")
    if [ "$WARN_COUNT" -eq 0 ]; then
        pass "No warnings in recent logs"
    elif [ "$WARN_COUNT" -lt 10 ]; then
        pass "Found ${WARN_COUNT} warnings in recent logs (acceptable)"
    else
        warn "Found ${WARN_COUNT} warnings in recent logs"
    fi
else
    warn "Log file not available for analysis"
fi

