#!/usr/bin/env bash
# Hub Integration Checks

section "TEST 3: Hub Integration Checks"

# Check if server connected to Hub
TODAY_LOG="logs/log-$(date +%Y%m%d).txt"
if check_in_file "Connected to AssettoServer Hub" "$TODAY_LOG" "Game Server connected to Hub"; then
    :
fi

# Check Hub Discord connection
if check_in_file "Discord:Gateway.*Ready" "hub/hub.log" "Hub connected to Discord"; then
    :
fi

# Check Hub database
if [ -f "hub/Hub.db" ]; then
    DB_SIZE=$(du -h hub/Hub.db | cut -f1)
    pass "Hub database exists (${DB_SIZE})"
else
    fail "Hub database NOT found"
fi

