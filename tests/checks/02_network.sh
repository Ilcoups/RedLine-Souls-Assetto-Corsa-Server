#!/usr/bin/env bash
# Network & Port Checks

section "TEST 2: Network & Port Checks"

# Define required ports
declare -A PORTS=(
    ["9600"]="Game port"
    ["8081"]="HTTP port"
    ["5085"]="Hub gRPC port"
    ["8000"]="Hub Web Interface port"
    ["8082"]="Audio Server port"
)

# Check all ports
for port in "${!PORTS[@]}"; do
    check_port "$port" "TCP" "${PORTS[$port]}"
done

