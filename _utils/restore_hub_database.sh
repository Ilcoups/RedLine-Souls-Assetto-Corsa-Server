#!/bin/bash
# Database restore utility - safely restore from backup

BACKUP_DIR="/home/acserver/server/_archive/hub_backups"
DB_PATH="/home/acserver/server/hub/Hub.db"

echo "🔄 Hub Database Restore Utility"
echo "================================"
echo ""

# Show available backups
echo "📁 Available backups:"
echo ""
echo "EMERGENCY BACKUPS:"
ls -lh "$BACKUP_DIR/emergency/" 2>/dev/null | tail -n +2 || echo "  No emergency backups"
echo ""
echo "DAILY BACKUPS (last 5):"
ls -lht "$BACKUP_DIR/daily/" 2>/dev/null | head -n 6 | tail -n +2 || echo "  No daily backups"
echo ""
echo "WEEKLY BACKUPS:"
ls -lh "$BACKUP_DIR/weekly/" 2>/dev/null | tail -n +2 || echo "  No weekly backups"
echo ""
echo "MONTHLY BACKUPS:"
ls -lh "$BACKUP_DIR/monthly/" 2>/dev/null | tail -n +2 || echo "  No monthly backups"
echo ""

if [ -z "$1" ]; then
    echo "Usage: $0 <backup_file_path>"
    echo ""
    echo "Example:"
    echo "  $0 $BACKUP_DIR/emergency/Hub_EMERGENCY_20251111_135020_before_redesign_testing.db"
    exit 0
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ ERROR: Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "⚠️  RESTORE OPERATION"
echo "  From: $BACKUP_FILE"
echo "  To:   $DB_PATH"
echo ""
echo "This will:"
echo "  1. Create emergency backup of current database"
echo "  2. Stop Hub service (if running)"
echo "  3. Restore the selected backup"
echo "  4. Verify integrity"
echo ""
read -p "Continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled."
    exit 0
fi

# Create emergency backup of current state
echo ""
echo "📦 Creating emergency backup of current database..."
/home/acserver/server/_utils/emergency_backup.sh "before_restore_$(basename $BACKUP_FILE)"

# Restore
echo ""
echo "🔄 Restoring database..."
cp "$BACKUP_FILE" "$DB_PATH"

if [ $? -eq 0 ]; then
    echo "✅ Database restored successfully!"
    echo ""
    echo "⚠️  Remember to restart Hub service if needed:"
    echo "  ./restart_all.sh"
else
    echo "❌ Restore failed!"
    exit 1
fi
