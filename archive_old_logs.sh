#!/bin/bash
# Archive old server logs (keeps last 7 days, archives older ones)
# No external dependencies - uses built-in gzip

LOG_DIR="/home/acserver/server/logs"
ARCHIVE_DIR="/home/acserver/server/logs/archive"
KEEP_DAYS=7

# Create archive directory if it doesn't exist
mkdir -p "$ARCHIVE_DIR"

echo "🗃️  Archiving old logs..."

# Find logs older than KEEP_DAYS days
find "$LOG_DIR" -maxdepth 1 -name "log-*.txt" -type f -mtime +$KEEP_DAYS | while read -r logfile; do
    filename=$(basename "$logfile")
    
    # Compress with gzip (built-in)
    echo "  Archiving: $filename"
    gzip -c "$logfile" > "$ARCHIVE_DIR/${filename}.gz"
    
    # Remove original if compression succeeded
    if [ $? -eq 0 ]; then
        rm "$logfile"
        echo "  ✓ Compressed and moved to archive/"
    else
        echo "  ✗ Failed to compress $filename"
    fi
done

# Count files
log_count=$(ls -1 "$LOG_DIR"/log-*.txt 2>/dev/null | wc -l)
archive_count=$(ls -1 "$ARCHIVE_DIR"/*.gz 2>/dev/null | wc -l)

echo ""
echo "✓ Archive complete!"
echo "  Active logs: $log_count"
echo "  Archived logs: $archive_count"
echo "  Archive location: $ARCHIVE_DIR"

# Show disk usage
echo ""
echo "📊 Disk usage:"
du -sh "$LOG_DIR"
du -sh "$ARCHIVE_DIR" 2>/dev/null || echo "  Archive: 0B"
