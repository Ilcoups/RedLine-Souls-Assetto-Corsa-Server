#!/usr/bin/env bash
# File System & Permissions Checks

section "TEST 5: File System & Permissions"

# Check log directory
check_writable_dir "logs" "Log directory"

# Check today's log file
TODAY_LOG="logs/log-$(date +%Y%m%d).txt"
if [ -f "$TODAY_LOG" ]; then
    LOG_SIZE=$(du -h "$TODAY_LOG" | cut -f1)
    pass "Today's log file exists (${LOG_SIZE})"
else
    warn "Today's log file not created yet"
fi

# Check disk space
DISK_AVAIL=$(get_disk_available .)
DISK_USAGE=$(get_disk_usage .)

if [ "$DISK_USAGE" -lt 90 ]; then
    pass "Disk space available: ${DISK_AVAIL} (${DISK_USAGE}% used)"
else
    warn "Disk space low: ${DISK_AVAIL} remaining (${DISK_USAGE}% used)"
fi

