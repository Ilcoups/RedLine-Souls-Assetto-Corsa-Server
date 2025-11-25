#!/usr/bin/env bash
# Comprehensive Server Backup Script
# Creates atomic, verified backups of critical data
# 
# CRITICAL DESIGN DECISIONS:
# - Uses SQLite .backup command (safer than cp during writes)
# - Validates backup integrity before committing
# - Atomic operations (temp dir → final location)
# - Comprehensive error handling
# - Automatic cleanup of old backups

set -euo pipefail

# Configuration
BACKUP_BASE="/home/acserver/backups"
SERVER_DIR="/home/acserver/server"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUP_BASE/$TIMESTAMP"
RETENTION_DAYS=30
MIN_FREE_SPACE_MB=1000

# Logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$BACKUP_BASE/backup.log"
}

error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" | tee -a "$BACKUP_BASE/backup.log" >&2
}

# Create backup base directory
mkdir -p "$BACKUP_BASE"

log "========================================="
log "BACKUP STARTED: $TIMESTAMP"
log "========================================="

# CRITICAL CHECK: Verify enough disk space
AVAILABLE_MB=$(df -BM "$BACKUP_BASE" | awk 'NR==2 {print $4}' | tr -d 'M')
if [ "$AVAILABLE_MB" -lt "$MIN_FREE_SPACE_MB" ]; then
    error "Insufficient disk space: ${AVAILABLE_MB}MB available, need ${MIN_FREE_SPACE_MB}MB"
    exit 1
fi
log "✓ Disk space check passed: ${AVAILABLE_MB}MB available"

# Create temporary backup directory (atomic operation)
TEMP_DIR=$(mktemp -d "$BACKUP_BASE/tmp_backup_XXXXXX")
trap "rm -rf '$TEMP_DIR'" EXIT

log "Using temporary directory: $TEMP_DIR"

# ===========================================================================
# BACKUP 1: Player Stats JSON
# ===========================================================================
log "Backing up player_stats.json..."

if [ -f "$SERVER_DIR/player_stats.json" ]; then
    # Use flock to prevent corruption during write
    if command -v flock >/dev/null 2>&1; then
        flock -n "$SERVER_DIR/player_stats.json" cp "$SERVER_DIR/player_stats.json" "$TEMP_DIR/player_stats.json" 2>/dev/null || {
            error "player_stats.json is locked, attempting unsafe copy..."
            cp "$SERVER_DIR/player_stats.json" "$TEMP_DIR/player_stats.json"
        }
    else
        cp "$SERVER_DIR/player_stats.json" "$TEMP_DIR/player_stats.json"
    fi
    
    # CRITICAL: Validate JSON integrity
    if python3 -m json.tool "$TEMP_DIR/player_stats.json" >/dev/null 2>&1; then
        SIZE=$(du -h "$TEMP_DIR/player_stats.json" | cut -f1)
        log "  ✓ player_stats.json backed up and validated ($SIZE)"
    else
        error "  ✗ player_stats.json is CORRUPTED in backup!"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
else
    log "  ⚠ player_stats.json not found (may not exist yet)"
fi

# ===========================================================================
# BACKUP 2: Hub Database (SQLite)
# ===========================================================================
log "Backing up Hub database..."

if [ -f "$SERVER_DIR/hub/Hub.db" ]; then
    # CRITICAL: Use SQLite's .backup command for safe backup during writes
    if command -v sqlite3 >/dev/null 2>&1; then
        sqlite3 "$SERVER_DIR/hub/Hub.db" ".backup '$TEMP_DIR/Hub.db'" 2>/dev/null || {
            error "SQLite backup command failed, trying file copy..."
            cp "$SERVER_DIR/hub/Hub.db" "$TEMP_DIR/Hub.db"
        }
    else
        # Fallback to file copy (less safe)
        cp "$SERVER_DIR/hub/Hub.db" "$TEMP_DIR/Hub.db"
    fi
    
    # CRITICAL: Validate database integrity
    if command -v sqlite3 >/dev/null 2>&1; then
        if sqlite3 "$TEMP_DIR/Hub.db" "PRAGMA integrity_check;" | grep -q "ok"; then
            SIZE=$(du -h "$TEMP_DIR/Hub.db" | cut -f1)
            log "  ✓ Hub.db backed up and validated ($SIZE)"
        else
            error "  ✗ Hub.db INTEGRITY CHECK FAILED!"
            rm -rf "$TEMP_DIR"
            exit 1
        fi
    else
        SIZE=$(du -h "$TEMP_DIR/Hub.db" | cut -f1)
        log "  ⚠ Hub.db backed up ($SIZE) but integrity not verified (sqlite3 not available)"
    fi
else
    log "  ⚠ Hub.db not found"
fi

# ===========================================================================
# BACKUP 3: Configuration Files
# ===========================================================================
log "Backing up configuration files..."

mkdir -p "$TEMP_DIR/cfg"
mkdir -p "$TEMP_DIR/hub"

# Critical config files
CONFIG_FILES=(
    "cfg/extra_cfg.yml"
    "cfg/server_cfg.ini"
    "cfg/csp_extra_options.ini"
    "hub/configuration.yml"
    ".env"
)

for file in "${CONFIG_FILES[@]}"; do
    if [ -f "$SERVER_DIR/$file" ]; then
        mkdir -p "$TEMP_DIR/$(dirname "$file")"
        cp "$SERVER_DIR/$file" "$TEMP_DIR/$file"
        log "  ✓ Backed up $file"
    fi
done

# ===========================================================================
# BACKUP 4: Service Files
# ===========================================================================
log "Backing up service files..."

SERVICE_FILES=(
    "unified-announcer.service"
    "restart_all.sh"
    "start_server.sh"
    "stop_server.sh"
)

for file in "${SERVICE_FILES[@]}"; do
    if [ -f "$SERVER_DIR/$file" ]; then
        cp "$SERVER_DIR/$file" "$TEMP_DIR/$file"
        log "  ✓ Backed up $file"
    fi
done

# ===========================================================================
# CREATE MANIFEST
# ===========================================================================
log "Creating backup manifest..."

cat > "$TEMP_DIR/BACKUP_MANIFEST.txt" << EOF
Backup Timestamp: $TIMESTAMP
Created: $(date +'%Y-%m-%d %H:%M:%S %Z')
Hostname: $(hostname)
Server Directory: $SERVER_DIR

Files Backed Up:
$(find "$TEMP_DIR" -type f -exec basename {} \; | sort)

Checksums (SHA256):
$(find "$TEMP_DIR" -type f ! -name "BACKUP_MANIFEST.txt" -exec sha256sum {} \; | sort -k2)

Total Size: $(du -sh "$TEMP_DIR" | cut -f1)
EOF

log "✓ Manifest created"

# ===========================================================================
# ATOMIC MOVE & COMPRESS
# ===========================================================================
log "Finalizing backup..."

# Move temp directory to final location (atomic operation)
mv "$TEMP_DIR" "$BACKUP_DIR"

# Compress backup
log "Compressing backup..."
tar -czf "$BACKUP_DIR.tar.gz" -C "$BACKUP_BASE" "$(basename "$BACKUP_DIR")" 2>/dev/null

if [ -f "$BACKUP_DIR.tar.gz" ]; then
    COMPRESSED_SIZE=$(du -h "$BACKUP_DIR.tar.gz" | cut -f1)
    ORIG_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
    log "  ✓ Compressed: $ORIG_SIZE → $COMPRESSED_SIZE"
    
    # Remove uncompressed directory
    rm -rf "$BACKUP_DIR"
else
    error "Compression failed!"
    exit 1
fi

# ===========================================================================
# CLEANUP OLD BACKUPS
# ===========================================================================
log "Cleaning up old backups (keeping last $RETENTION_DAYS days)..."

OLD_BACKUPS=$(find "$BACKUP_BASE" -name "*.tar.gz" -type f -mtime +$RETENTION_DAYS 2>/dev/null)
if [ -n "$OLD_BACKUPS" ]; then
    echo "$OLD_BACKUPS" | while read -r old_backup; do
        rm -f "$old_backup"
        log "  Deleted: $(basename "$old_backup")"
    done
else
    log "  No old backups to clean"
fi

# ===========================================================================
# FINAL VERIFICATION
# ===========================================================================
log "Final verification..."

if [ -f "$BACKUP_DIR.tar.gz" ]; then
    # Verify tar integrity
    if tar -tzf "$BACKUP_DIR.tar.gz" >/dev/null 2>&1; then
        log "✓ Backup archive verified"
    else
        error "Backup archive is CORRUPTED!"
        exit 1
    fi
fi

# ===========================================================================
# SUMMARY
# ===========================================================================
log "========================================="
log "BACKUP COMPLETED SUCCESSFULLY"
log "========================================="
log "Location: $BACKUP_DIR.tar.gz"
log "Size: $(du -h "$BACKUP_DIR.tar.gz" | cut -f1)"

# List all current backups
log ""
log "Current backups:"
ls -lh "$BACKUP_BASE"/*.tar.gz 2>/dev/null | tail -5 | awk '{print "  " $9 " (" $5 ")"}'

log ""
log "To restore:"
log "  tar -xzf $BACKUP_DIR.tar.gz -C /tmp"
log "  # Then manually restore files as needed"

# Clear trap since we're exiting cleanly
trap - EXIT

exit 0

