# Hub Database Backup System

## Overview
Automatic multi-tier backup system for the Hub database with daily, weekly, and monthly archives plus emergency backups.

## Backup Schedule

**Automatic Backups (via systemd timer):**
- Every 6 hours: 00:00, 06:00, 12:00, 18:00 UTC
- Daily at 04:00 UTC
- 5 minutes after system boot
- Runs missed backups if system was offline

**Retention Policy:**
- **Daily**: Last 30 days
- **Weekly**: Last 12 weeks (~3 months)
- **Monthly**: Forever (never auto-deleted)
- **Emergency**: Forever (manual only)

## Backup Locations
```
_archive/hub_backups/
├── daily/          # Last 30 days of daily backups
├── weekly/         # Last 12 weekly backups (Sundays)
├── monthly/        # All monthly backups (1st of month)
└── emergency/      # Manual emergency backups
```

## Usage

### Automatic Backups (Already Running)
```bash
# Check backup timer status
systemctl --user status hub-backup.timer

# View backup logs
journalctl --user -u hub-backup.service

# Manually trigger backup now
systemctl --user start hub-backup.service
```

### Emergency Manual Backup (Before Risky Changes)
```bash
# Create emergency backup with reason
./_utils/emergency_backup.sh "before_plugin_update"
./_utils/emergency_backup.sh "before_schema_change"
./_utils/emergency_backup.sh "server_acting_weird"

# Without reason (generic name)
./_utils/emergency_backup.sh
```

### Restore from Backup
```bash
# List all available backups
./_utils/restore_hub_database.sh

# Restore specific backup (interactive with confirmation)
./_utils/restore_hub_database.sh /home/acserver/server/_archive/hub_backups/emergency/Hub_EMERGENCY_20251111_135020_before_redesign_testing.db
```

## What Gets Backed Up
- Complete Hub.db database (all tables)
- Player statistics
- Leaderboard entries
- Car information
- Discord integration data

## Backup File Naming
```
Daily:     Hub_20251111_143000.db
Weekly:    Hub_week_20251111.db
Monthly:   Hub_month_20251111.db
Emergency: Hub_EMERGENCY_20251111_143000_reason.db
```

## Recovery Scenarios

### 1. Database Corruption
```bash
# List recent backups
./_utils/restore_hub_database.sh

# Restore from last good backup
./_utils/restore_hub_database.sh _archive/hub_backups/daily/Hub_20251111_120000.db
./restart_all.sh
```

### 2. Accidental Data Loss
```bash
# Find backup from before the incident
ls -lht _archive/hub_backups/daily/

# Restore it
./_utils/restore_hub_database.sh _archive/hub_backups/daily/Hub_20251110_040000.db
```

### 3. Plugin/Update Gone Wrong
```bash
# Create emergency backup BEFORE risky operation
./_utils/emergency_backup.sh "before_risky_update"

# If something breaks, restore from emergency backup
./_utils/restore_hub_database.sh _archive/hub_backups/emergency/Hub_EMERGENCY_*_before_risky_update.db
```

## Monitoring

### Check Backup Health
```bash
# Run backup script manually to see stats
./_utils/backup_hub_database.sh

# Output shows:
#   ✓ Daily backup created: path
#   Database: 23 entries, 23 players, 224K
#   Backup summary with counts
```

### Verify Backup Integrity
Backups are verified on creation:
- File exists and has size
- Can be opened by Python sqlite3
- Entry/player counts are retrievable

## Troubleshooting

### Timer Not Running
```bash
systemctl --user status hub-backup.timer
systemctl --user start hub-backup.timer
```

### Backups Not Creating
```bash
# Check service logs
journalctl --user -u hub-backup.service -n 50

# Run manually to see errors
./_utils/backup_hub_database.sh
```

### Restore Failed
```bash
# Verify backup file exists and is readable
ls -lh /path/to/backup.db
file /path/to/backup.db  # Should say "SQLite 3.x database"
```

## Best Practices

1. **Before risky operations**: Always create emergency backup
2. **Regular checks**: Verify backups are running weekly
3. **Test restores**: Practice restore process when not under pressure
4. **Document reasons**: Use descriptive names for emergency backups
5. **Keep emergency backups**: Never delete emergency backups manually

## Integration with Server Operations

The backup system runs independently and doesn't interfere with:
- AssettoServer operation
- Hub service
- Discord integration
- Player connections

Backups are taken while services are running (SQLite handles this safely).

## Disk Space Management

Current database: ~224KB
With retention policy:
- 30 daily backups: ~7 MB
- 12 weekly backups: ~3 MB
- Monthly backups: ~3 MB/year
- Emergency backups: varies (manual cleanup)

**Total estimated usage**: <50 MB for first year

Clean up old emergency backups manually when needed:
```bash
ls -lht _archive/hub_backups/emergency/
rm _archive/hub_backups/emergency/Hub_EMERGENCY_old_backup.db
```

## Scripts Reference

| Script | Purpose | Usage |
|--------|---------|-------|
| `backup_hub_database.sh` | Automatic daily/weekly/monthly backups | Run by timer or manual |
| `emergency_backup.sh` | Quick manual backup before risky ops | `./emergency_backup.sh "reason"` |
| `restore_hub_database.sh` | Safe restore with confirmation | `./restore_hub_database.sh backup.db` |

---

**System Status**: ✅ Active and running
**Next backup**: Check with `systemctl --user list-timers hub-backup.timer`
