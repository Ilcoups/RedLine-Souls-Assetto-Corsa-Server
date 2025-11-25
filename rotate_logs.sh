#!/bin/bash
# User-space log rotation (no sudo needed)
# Rotates logs daily, keeps 7 days, compresses old ones

LOG_DIR="/home/acserver/server/logs"
DAYS_TO_KEEP=7

# Function to rotate a single log file
rotate_log() {
    local logfile="$1"
    local basename=$(basename "$logfile")
    
    # Skip if file doesn't exist or is empty
    [ ! -f "$logfile" ] && return
    [ ! -s "$logfile" ] && return
    
    # Create dated backup
    local today=$(date +%Y%m%d)
    local backup="${logfile}.${today}"
    
    # If backup already exists today, skip
    [ -f "$backup" ] && return
    
    # Copy and truncate (keeps file open for writing processes)
    cp "$logfile" "$backup"
    : > "$logfile"
    
    # Compress yesterday's backup
    local yesterday=$(date -d "yesterday" +%Y%m%d)
    local yesterday_backup="${logfile}.${yesterday}"
    if [ -f "$yesterday_backup" ] && [ ! -f "${yesterday_backup}.gz" ]; then
        gzip "$yesterday_backup"
    fi
    
    echo "$(date): Rotated $basename"
}

# Function to clean old logs
clean_old_logs() {
    local logfile="$1"
    
    # Delete backups older than DAYS_TO_KEEP
    find "$LOG_DIR" -name "$(basename $logfile).*" -type f -mtime +$DAYS_TO_KEEP -delete
    
    echo "$(date): Cleaned old backups for $(basename $logfile)"
}

# Main rotation
echo "=== Log Rotation Started: $(date) ==="

# Rotate all .log files
for logfile in "$LOG_DIR"/*.log; do
    rotate_log "$logfile"
    clean_old_logs "$logfile"
done

echo "=== Log Rotation Complete: $(date) ==="
