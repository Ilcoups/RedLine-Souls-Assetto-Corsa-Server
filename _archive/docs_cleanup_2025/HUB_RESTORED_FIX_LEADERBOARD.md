# ✅ Hub Restored - Leaderboard Fix Instructions

**Date**: November 10, 2025, 23:28 UTC  
**Status**: Hub is RUNNING and STABLE

## 🎯 What Was Fixed

1. **Hub restored to stable state** using backups from earlier today
2. **Database**: `Hub.db.before_discord_fix` (23:16 today)
3. **Configuration**: `configuration.yml.backup_before_fix` (21:36 today)
4. **Hub Status**: ✓ Running, Discord bot connected

## 📊 Current Leaderboard Status

### What's Working:
- ✅ Hub is receiving overtake scores from game server
- ✅ Discord bot is connected
- ✅ Discord leaderboard message exists and updates every minute
- ✅ All 24 overtake entries are saved in database

### What's Still Showing "No Data":
- ❌ Discord leaderboard displays "No leaderboard data yet"
- **Reason**: Discord leaderboard is linked to OLD table (1 entry from Nov 7)
- **Active scores**: In NEW table (`overtake_n_leaderboard_entries` - 24 entries)

## 🔧 How To Fix The Leaderboard (Simple Steps)

**You need to recreate the Discord leaderboard link:**

1. **Go to Discord**
   - Open your Discord server
   - Navigate to the `#leaderboard` channel

2. **Delete the current leaderboard message** (optional but clean)
   - Right-click the leaderboard message
   - Delete it

3. **Run the bot command:**
   ```
   /overtake-leaderboard
   ```

4. **When prompted for leaderboard name, type:**
   ```
   RedLine Souls
   ```

5. **The bot will create a NEW leaderboard**
   - It should auto-detect the correct table with 24 entries
   - Leaderboard will show current player scores
   - Updates automatically every 60 seconds

## 📋 Database Information

### Overtake Leaderboard Tables:
```
OLD: overtake_leaderboard_entries
  - 1 entry (Nov 7, 152,384 points)
  - Discord leaderboard currently points here

NEW: overtake_n_leaderboard_entries  
  - 24 entries (Nov 9-10)
  - Current scores being saved here
  - Latest: 25 points at Nov 10 22:27:10
```

### Discord Leaderboard Config (in database):
```
Leaderboard: "RedLine Souls"
Channel: 1436335034868170754
Message: 1436359923306070199
Template: "default"
Entries to show: 15
```

## 🛠️ If Hub Needs Restart

```bash
# Stop Hub
pkill -9 -f AssettoServer.Hub
sleep 3

# Check port is free
lsof -i :5085 || echo "Port is free"

# Start Hub
cd /home/acserver/server
./start_hub.sh

# Verify it's running
sleep 5
tail -5 /home/acserver/server/hub/hub.log
```

Look for: `[Discord:Gateway] Ready`

## 📁 Files Backed Up

All modified files have timestamped backups:
```
/home/acserver/server/hub/Hub.db.broken_20251110_232830
/home/acserver/server/hub/configuration.yml.broken_20251110_232830
/home/acserver/server/LEADERBOARD_INVESTIGATION_2025-11-10.md (documentation)
```

## ⚠️ What NOT To Do

1. ❌ Don't manually edit the database discord_overtake_leaderboards table
2. ❌ Don't delete configuration.yml without a backup
3. ❌ Use backups if Hub breaks:
   - Database: `Hub.db.before_discord_fix`
   - Config: `configuration.yml.backup_before_fix`

## 🎮 Current Server Status

- **Game Server**: Running, connected to Hub
- **Hub**: Running, Discord bot active
- **Overtake Plugin**: Working, scores being recorded
- **Discord Leaderboard**: Updating (but showing "no data" until recreated)

## 📖 Related Documentation

- `LEADERBOARD_INVESTIGATION_2025-11-10.md` - Full technical investigation
- `DISCORD_LEADERBOARD_SETUP.md` - Original setup guide
- `HUB_SETUP_COMPLETE.md` - Initial Hub configuration

---

**Next Action**: Run `/overtake-leaderboard` in Discord to create fresh leaderboard link to the active data table!
