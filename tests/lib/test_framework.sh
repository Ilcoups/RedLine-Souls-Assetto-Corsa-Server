#!/usr/bin/env bash
# Test Framework Library
# Provides reusable test functions and utilities

# Color codes
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export NC='\033[0m' # No Color

# Test counters (use in parent script)
declare -g ERRORS=0
declare -g WARNINGS=0
declare -g PASSES=0

# Test result functions
pass() {
    echo -e "${GREEN}✅ PASS${NC}: $1"
    PASSES=$((PASSES + 1))
}

fail() {
    echo -e "${RED}❌ FAIL${NC}: $1"
    ERRORS=$((ERRORS + 1))
}

warn() {
    echo -e "${YELLOW}⚠️  WARN${NC}: $1"
    WARNINGS=$((WARNINGS + 1))
}

info() {
    echo -e "${BLUE}ℹ️  INFO${NC}: $1"
}

# Section header
section() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Retry wrapper for flaky operations
retry_command() {
    local max_attempts="${1:-3}"
    shift
    local delay="${1:-2}"
    shift
    
    for attempt in $(seq 1 "$max_attempts"); do
        if "$@"; then
            return 0
        fi
        
        if [ "$attempt" -lt "$max_attempts" ]; then
            sleep "$delay"
        fi
    done
    
    return 1
}

# Check if process is running by name
check_process() {
    local process_name="$1"
    local display_name="$2"
    
    if pgrep -f "$process_name" >/dev/null 2>&1; then
        local pid=$(pgrep -f "$process_name" | head -1)
        pass "$display_name running (PID: $pid)"
        return 0
    else
        fail "$display_name NOT running"
        return 1
    fi
}

# Check if port is listening (with retry)
check_port() {
    local port="$1"
    local protocol="${2:-TCP}"
    local description="$3"
    
    if retry_command 2 1 netstat -tln 2>/dev/null | grep -q ":${port} " || \
       retry_command 2 1 ss -tln 2>/dev/null | grep -q ":${port} "; then
        pass "$description port $port ($protocol) listening"
        return 0
    else
        fail "$description port $port ($protocol) NOT listening"
        return 1
    fi
}

# Check if file exists and is readable
check_file() {
    local file_path="$1"
    local description="$2"
    
    if [ -f "$file_path" ]; then
        pass "$description exists"
        return 0
    else
        fail "$description NOT found: $file_path"
        return 1
    fi
}

# Check if directory exists and is writable
check_writable_dir() {
    local dir_path="$1"
    local description="$2"
    
    if [ -d "$dir_path" ] && [ -w "$dir_path" ]; then
        pass "$description writable"
        return 0
    else
        fail "$description not writable: $dir_path"
        return 1
    fi
}

# Check if string exists in file
check_in_file() {
    local pattern="$1"
    local file_path="$2"
    local description="$3"
    
    if grep -q "$pattern" "$file_path" 2>/dev/null; then
        pass "$description"
        return 0
    else
        fail "$description - pattern not found"
        return 1
    fi
}

# Get CPU usage for PID
get_cpu_usage() {
    local pid="$1"
    ps -p "$pid" -o %cpu --no-headers 2>/dev/null | xargs
}

# Get memory usage for PID
get_mem_usage() {
    local pid="$1"
    ps -p "$pid" -o %mem --no-headers 2>/dev/null | xargs
}

# Check systemd service
check_systemd_service() {
    local service_name="$1"
    local description="$2"
    
    if systemctl --user is-active --quiet "$service_name" 2>/dev/null; then
        pass "$description active"
        return 0
    else
        fail "$description NOT active"
        return 1
    fi
}

# Get disk usage percentage
get_disk_usage() {
    local path="${1:-.}"
    df -h "$path" | awk 'NR==2 {print $5}' | tr -d '%'
}

# Get available disk space
get_disk_available() {
    local path="${1:-.}"
    df -h "$path" | awk 'NR==2 {print $4}'
}

# Count errors in log
count_log_errors() {
    local log_file="$1"
    local lines="${2:-100}"
    local pattern="${3:-\[ERR\]}"
    
    tail -"$lines" "$log_file" 2>/dev/null | { grep -c "$pattern" || true; }
}

# Safe command execution
safe_exec() {
    "$@" 2>/dev/null || true
}

# Export all functions
export -f pass fail warn info section retry_command
export -f check_process check_port check_file check_writable_dir check_in_file
export -f get_cpu_usage get_mem_usage check_systemd_service
export -f get_disk_usage get_disk_available count_log_errors safe_exec
