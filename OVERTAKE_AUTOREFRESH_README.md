# Overtake PB Auto-Refresh System

## What It Does
- **Top 10 Players**: Hardcoded PBs for ranks 1-10
- **Auto-Updates**: Daemon checks database every 60 seconds
- **Safe Refresh**: Updates Lua file only when data changes
- **No Interruption**: Active players keep scoring, only new joins get updated PBs

## Components

### 1. Lua Script (`overtake.lua`)
- Checks player's Steam ID on first `script.update()` call  
- Loads PB from hardcoded top 10 list
- Shows "PB: 0 pts" for players outside top 10

### 2. Auto-Update Daemon (`pb_autoupdate_daemon.py`)
- **Status**: Running (PID in `/tmp/pb_autoupdate.pid`)
- **Update Interval**: 60 seconds
- **Log File**: `logs/pb_autoupdate.log`
- **Change Detection**: Only updates file when top 10 changes

## How It Works

**For Active Players:**
1. Player joins server → Lua script loads → Checks Steam ID → Sets PB
2. Player scores points → Plugin tracks real-time score → NO INTERRUPTION
3. Daemon updates Lua file in background → Doesn't affect active players
4. Next player to join gets latest PB data

**For New Records:**
1. Player breaks their PB → Plugin saves to database
2. Within 60 seconds → Daemon detects change → Updates Lua file
3. Next time that player joins → Sees new PB immediately

## Important Notes

❗ **Active players won't see PB update until they reconnect**
- This is a CSP Lua limitation (no file reload or network access)
- But their scoring is NEVER interrupted
- PB display is informational only

✅ **What this solves:**
- Top 10 players always see correct PB on join
- Auto-updates when rankings change
- No manual intervention needed
- Scales to handle competitive leaderboard changes

## Daemon Management

**Start:**
```bash
python3 pb_autoupdate_daemon.py &
```

**Stop:**
```bash
kill $(cat /tmp/pb_autoupdate.pid)
```

**Check Status:**
```bash
tail -f logs/pb_autoupdate.log
```

**Manual Trigger:**
- Daemon runs automatically every 60 seconds
- No manual triggers needed

## Expanding to More Players

To expand beyond top 10, edit the daemon's query:
```python
LIMIT 10  # Change to 20, 50, etc.
```

File size considerations:
- 10 players: ~10KB ✅
- 50 players: ~25KB ✅  
- 100 players: ~50KB ⚠️ (may cause CSP slowdown)
