#!/usr/bin/env bash
# Log Health Analysis

section "TEST 6: Log Health Analysis"

TODAY_LOG="logs/log-$(date +%Y%m%d).txt"

if [ -f "$TODAY_LOG" ]; then
    # Check for errors
    ERROR_COUNT=$(count_log_errors "$TODAY_LOG" 100 "\[ERR\]")
    if [ "$ERROR_COUNT" -eq 0 ]; then
        pass "No errors in recent logs"
    else
        warn "Found ${ERROR_COUNT} errors in recent logs"
    fi
    
    # Check for warnings
    WARN_COUNT=$(count_log_errors "$TODAY_LOG" 100 "\[WRN\]")
    if [ "$WARN_COUNT" -eq 0 ]; then
        pass "No warnings in recent logs"
    elif [ "$WARN_COUNT" -lt 5 ]; then
        info "Found ${WARN_COUNT} warnings in recent logs (acceptable)"
    else
        warn "Found ${WARN_COUNT} warnings in recent logs"
    fi
else
    warn "Log file not available for analysis"
fi

