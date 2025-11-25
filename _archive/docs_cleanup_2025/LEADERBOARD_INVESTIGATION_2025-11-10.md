# Leaderboard Investigation - November 10, 2025

## 🔍 Issue Reported
Discord leaderboard showing "No leaderboard data yet" despite being configured and updating every minute.

## 🕵️ Investigation Findings

### Root Cause Discovered
1. **Overtake scores ARE being saved** - Hub is receiving them correctly
2. **Wrong database table being used** for Discord leaderboard display
3. There are TWO overtake leaderboard systems in the Hub database:
   - `overtake_leaderboards` / `overtake_leaderboard_entries` (OLD - 1 entry from Nov 7)
   - `overtake_n_leaderboards` / `overtake_n_leaderboard_entries` (NEW - 24 entries, actively used)

### Database Analysis
```
overtake_leaderboard_entries (OLD table):
  - 1 entry from Nov 7, 2025
  - Player: 76561199185532445
  - Score: 152,384 points

overtake_n_leaderboard_entries (NEW table):
  - 24 entries (most recent: Nov 10, 22:27:10)
  - Latest: 25 points from player 76561198776019625
  - This is where current scores are being saved!
```

### Discord Leaderboard Configuration
```
Leaderboard Name: "RedLine Souls"
Channel ID: 1436335034868170754
Message ID: 1436359923306070199
Template: "default"
num_entries: Was 0, updated to 15
```

### Game Server Configuration
```yaml
PatreonOvertakePlugin: Enabled ✓
LeaderboardName: RedLine Souls ✓
Hub Connection: Working ✓
```

## ❌ Problems Identified

1. **Discord leaderboard reads from OLD table** (`overtake_leaderboard_entries`)
2. **New scores go to NEW table** (`overtake_n_leaderboard_entries`)
3. **Mismatch causes "No data" message** despite 24 active entries

## 🔧 Attempted Fixes

### Fix #1: Template Syntax Error
- **Issue**: Template had orphaned `{{ else }}` block causing Hub errors
- **Fix**: Corrected Scriban template syntax with proper `-` modifiers
- **Result**: Fixed template errors, but data still not showing

### Fix #2: Updated num_entries
- **Issue**: Discord leaderboard configured to show 0 entries
- **Fix**: Updated to 15 entries in database
- **Result**: Configuration correct, but still reading from wrong table

### Fix #3: Attempted Discord Leaderboard Recreation
- **Action**: Deleted discord_overtake_leaderboards entry to force recreation
- **Result**: Hub became unstable, needs Discord bot command to recreate

## 💡 Solution Required

The Discord leaderboard needs to be recreated using the `/overtake-leaderboard` bot command in Discord. This should:
1. Auto-detect the correct `overtake_n_leaderboards` table
2. Link to the 24 active entries
3. Display current leaderboard data

### Steps to Fix (NOT completed due to Hub instability):
1. Stop Hub
2. Delete old Discord leaderboard link from database
3. Restart Hub  
4. Run `/overtake-leaderboard` in Discord
5. Enter "RedLine Souls" as leaderboard name
6. Bot should create new link to correct table

## 📊 Data Recovery Status

**All overtake data is safe!** The 24 entries in `overtake_n_leaderboard_entries` are intact:
- Oldest: Nov 9, 2025
- Newest: Nov 10, 2025 22:27:10
- Multiple players tracked
- Scores ranging from 15 to 109,609 points

## ⚠️ Current State (End of Investigation)

- Hub configuration became unstable during fix attempts
- Template errors appeared when Discord leaderboard was deleted
- Recommendation: **Restore to stable git version and recreate Discord leaderboard cleanly**

## 📝 Key Learnings

1. Hub uses TWO different overtake leaderboard systems ("old" and "n" type)
2. Current server uses "n" type (newer system)
3. Discord leaderboard links must match the correct table type
4. Deleting Discord leaderboard requires `/overtake-leaderboard` command to recreate
5. Database integrity is maintained - all scores are safe

---
**Investigation Date**: November 10, 2025, 23:00-23:25 UTC
**Files Modified**: 
- `/home/acserver/server/hub/configuration.yml` (multiple backups created)
- `/home/acserver/server/hub/Hub.db` (num_entries updated, then discord link deleted)
**Backups Created**: 
- `Hub.db.before_fix_*`
- `Hub.db.before_discord_fix`
- Multiple configuration.yml backups
