#!/bin/bash
# Emergency manual backup - for use before risky operations
# Creates a backup in the emergency directory with descriptive name

DB_PATH="/home/acserver/server/hub/Hub.db"
EMERGENCY_DIR="/home/acserver/server/_archive/hub_backups/emergency"

mkdir -p "$EMERGENCY_DIR"

if [ ! -f "$DB_PATH" ]; then
    echo "ERROR: Database not found at $DB_PATH"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REASON="${1:-manual_backup}"
BACKUP_FILE="$EMERGENCY_DIR/Hub_EMERGENCY_${TIMESTAMP}_${REASON}.db"

cp "$DB_PATH" "$BACKUP_FILE"

if [ -f "$BACKUP_FILE" ] && [ -s "$BACKUP_FILE" ]; then
    DB_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "✓✓✓ EMERGENCY BACKUP CREATED ✓✓✓"
    echo "  Location: $BACKUP_FILE"
    echo "  Size: $DB_SIZE"
    echo "  Reason: $REASON"
    echo ""
    echo "To restore this backup later:"
    echo "  cp \"$BACKUP_FILE\" \"$DB_PATH\""
else
    echo "✗ ERROR: Emergency backup failed!"
    exit 1
fi
