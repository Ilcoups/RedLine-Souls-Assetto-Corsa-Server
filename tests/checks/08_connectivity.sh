#!/usr/bin/env bash
# External Connectivity Checks

section "TEST 8: External Connectivity"

# Test Hub web interface
if timeout 5 curl -s http://localhost:8000 >/dev/null 2>&1; then
    pass "Hub web interface accessible"
else
    warn "Hub web interface not accessible (may still be starting)"
fi

# Test DNS resolution
if timeout 3 host discord.com >/dev/null 2>&1; then
    pass "DNS resolution working"
else
    warn "DNS resolution issues detected"
fi

