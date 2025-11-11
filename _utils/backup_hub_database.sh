#!/bin/bash
# Automatic Hub database backup script
# Creates timestamped backups and maintains last 30 days + weekly/monthly archives

DB_PATH="/home/acserver/server/hub/Hub.db"
BACKUP_DIR="/home/acserver/server/_archive/hub_backups"
DAILY_DIR="$BACKUP_DIR/daily"
WEEKLY_DIR="$BACKUP_DIR/weekly"
MONTHLY_DIR="$BACKUP_DIR/monthly"
EMERGENCY_DIR="$BACKUP_DIR/emergency"

# Create backup directories if they don't exist
mkdir -p "$DAILY_DIR" "$WEEKLY_DIR" "$MONTHLY_DIR" "$EMERGENCY_DIR"

# Check if database exists
if [ ! -f "$DB_PATH" ]; then
    echo "ERROR: Database not found at $DB_PATH"
    exit 1
fi

# Generate timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DATE=$(date +%Y%m%d)
DAY_OF_WEEK=$(date +%u)  # 1 = Monday, 7 = Sunday
DAY_OF_MONTH=$(date +%d)

# Daily backup
DAILY_BACKUP="$DAILY_DIR/Hub_${TIMESTAMP}.db"
cp "$DB_PATH" "$DAILY_BACKUP"

# Verify backup was created and has size
if [ -f "$DAILY_BACKUP" ] && [ -s "$DAILY_BACKUP" ]; then
    echo "✓ Daily backup created: $DAILY_BACKUP"
    
    # Get database stats using Python (sqlite3 command not available)
    DB_SIZE=$(du -h "$DAILY_BACKUP" | cut -f1)
    STATS=$(python3 -c "
import sqlite3
conn = sqlite3.connect('$DAILY_BACKUP')
try:
    entries = conn.execute('SELECT COUNT(*) FROM overtake_n_leaderboard_entries').fetchone()[0]
    players = conn.execute('SELECT COUNT(DISTINCT player_id) FROM overtake_n_leaderboard_entries').fetchone()[0]
    print(f'{entries} entries, {players} players')
except:
    print('stats unavailable')
finally:
    conn.close()
" 2>/dev/null || echo "stats unavailable")
    echo "  Database: $STATS, $DB_SIZE"
else
    echo "✗ ERROR: Backup failed - file not created or empty!"
    exit 1
fi

# Weekly backup (every Sunday)
if [ "$DAY_OF_WEEK" -eq 7 ]; then
    WEEKLY_BACKUP="$WEEKLY_DIR/Hub_week_${DATE}.db"
    cp "$DAILY_BACKUP" "$WEEKLY_BACKUP"
    echo "✓ Weekly backup created: $WEEKLY_BACKUP"
fi

# Monthly backup (1st of month)
if [ "$DAY_OF_MONTH" -eq 01 ]; then
    MONTHLY_BACKUP="$MONTHLY_DIR/Hub_month_${DATE}.db"
    cp "$DAILY_BACKUP" "$MONTHLY_BACKUP"
    echo "✓ Monthly backup created: $MONTHLY_BACKUP"
fi

# Cleanup old daily backups (keep last 30 days)
find "$DAILY_DIR" -name "Hub_*.db" -type f -mtime +30 -delete
echo "✓ Cleaned up backups older than 30 days"

# Keep last 12 weekly backups (~3 months)
ls -t "$WEEKLY_DIR"/Hub_week_*.db 2>/dev/null | tail -n +13 | xargs -r rm
echo "✓ Kept last 12 weekly backups"

# Keep all monthly backups (never auto-delete)
MONTHLY_COUNT=$(ls -1 "$MONTHLY_DIR"/Hub_month_*.db 2>/dev/null | wc -l)
echo "✓ Monthly archives: $MONTHLY_COUNT backups"

echo ""
echo "Backup summary:"
echo "  Daily:   $(ls -1 "$DAILY_DIR" | wc -l) backups"
echo "  Weekly:  $(ls -1 "$WEEKLY_DIR" | wc -l) backups"
echo "  Monthly: $MONTHLY_COUNT backups"
echo "  Emergency: $(ls -1 "$EMERGENCY_DIR" | wc -l) backups"
