#!/usr/bin/env bash
# Production Readiness Test Runner
# Orchestrates modular test execution with error isolation and persistence

set -euo pipefail

# Determine test directory
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(cd "$TESTS_DIR/.." && pwd)"
cd "$BASE_DIR"

# Load test framework
source "$TESTS_DIR/lib/test_framework.sh"

# Initialize counters
ERRORS=0
WARNINGS=0
PASSES=0

# Test run metadata
TEST_RUN_ID="$(date +%Y%m%d_%H%M%S)"
RESULT_FILE="$TESTS_DIR/results/${TEST_RUN_ID}.log"
RESULT_JSON="$TESTS_DIR/results/${TEST_RUN_ID}.json"
START_TIME=$(date +%s)
START_TIMESTAMP=$(date -Iseconds)

# Ensure results directory exists
mkdir -p "$TESTS_DIR/results"

# Start logging
exec > >(tee "$RESULT_FILE") 2>&1

echo "========================================"
echo "  PRODUCTION READINESS TEST SUITE"
echo "========================================"
echo ""
echo "Run ID: $TEST_RUN_ID"
echo "Started: $START_TIMESTAMP"
echo ""
echo "Starting comprehensive checks..."

# Track module results
declare -a MODULE_RESULTS=()

# Run all test modules with ERROR ISOLATION and TIMEOUT PROTECTION
for test_module in "$TESTS_DIR/checks"/*.sh; do
    if [ -f "$test_module" ]; then
        module_name=$(basename "$test_module" .sh)
        module_start=$(date +%s)
        
        echo ""
        info "Running module: $module_name"
        
        # FIX #1: ERROR ISOLATION - Don't let one module failure kill entire suite
        # FIX #3: TIMEOUT PROTECTION - Kill if hangs (implemented per-test in framework)
        set +e  # Temporarily disable pipefail for module execution
        source "$test_module"
        module_exit=$?
        set -e  # Re-enable
        
        # Only warn on truly bad exits (not normal test failures)
        if [ $module_exit -gt 1 ]; then
            warn "Module $module_name exited abnormally (code $module_exit)"
        fi
        
        module_end=$(date +%s)
        module_duration=$((module_end - module_start))
        
        # Store module result
        MODULE_RESULTS+=("$module_name:$module_duration")
    fi
done

# Calculate execution time
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
END_TIMESTAMP=$(date -Iseconds)

# Final report
echo ""
echo "========================================"
echo "  TEST RESULTS SUMMARY"
echo "========================================"
echo ""

# Calculate total tests
TOTAL_TESTS=$((PASSES + ERRORS + WARNINGS))

# Display summary
info "Total checks: $TOTAL_TESTS"
echo -e "${GREEN}  Passed:   $PASSES${NC}"
echo -e "${YELLOW}  Warnings: $WARNINGS${NC}"
echo -e "${RED}  Errors:   $ERRORS${NC}"
echo ""
info "Execution time: ${DURATION}s"
echo ""

# Determine exit status and message
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED!${NC}"
    echo ""
    echo "Server is PRODUCTION READY ✅"
    STATUS="passed"
    EXIT_CODE=0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  TESTS PASSED WITH WARNINGS${NC}"
    echo ""
    echo "Server is operational but review warnings."
    STATUS="passed_with_warnings"
    EXIT_CODE=0
else
    echo -e "${RED}❌ TESTS FAILED${NC}"
    echo ""
    echo "Server is NOT ready for production!"
    STATUS="failed"
    EXIT_CODE=1
fi

echo ""
echo "========================================"
echo "Completed: $(date)"
echo "========================================"
echo ""

# FIX #2: RESULT PERSISTENCE - Save structured JSON results
cat > "$RESULT_JSON" << EOF
{
  "run_id": "$TEST_RUN_ID",
  "start_time": "$START_TIMESTAMP",
  "end_time": "$END_TIMESTAMP",
  "duration_seconds": $DURATION,
  "status": "$STATUS",
  "summary": {
    "total": $TOTAL_TESTS,
    "passed": $PASSES,
    "warnings": $WARNINGS,
    "errors": $ERRORS
  },
  "modules": [
$(for result in "${MODULE_RESULTS[@]}"; do
    module="${result%%:*}"
    duration="${result##*:}"
    echo "    {\"name\": \"$module\", \"duration_seconds\": $duration},"
done | sed '$ s/,$//')
  ],
  "system": {
    "hostname": "$(hostname)",
    "user": "$(whoami)",
    "git_commit": "$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
  }
}
EOF

info "Results saved:"
echo "  • Log:  $RESULT_FILE"
echo "  • JSON: $RESULT_JSON"
echo ""

# Keep only last 30 days of results
find "$TESTS_DIR/results" -name "*.log" -mtime +30 -delete 2>/dev/null || true
find "$TESTS_DIR/results" -name "*.json" -mtime +30 -delete 2>/dev/null || true

exit $EXIT_CODE
