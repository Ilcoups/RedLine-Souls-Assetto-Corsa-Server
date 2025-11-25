#!/bin/bash
# Honeypot Monitoring Cron Job
# Runs daily to check if attacker tries to use leaked credentials

cd /home/acserver/server

echo "=== Honeypot Check - $(date) ===" >> logs/honeypot.log
python3 _utils/monitor_honeypot.py >> logs/honeypot.log 2>&1

# If honeypot was triggered, send alert
if [ $? -ne 0 ]; then
    echo "🚨 ALERT: Honeypot triggered at $(date)" >> logs/honeypot.log
    # Could add Discord notification here if needed
fi
