# Issues Fixed - Hub & Patreon Plugins Setup

## 🐛 Problems Encountered & Solutions

### 1. Hub Crashes When Player Connects
**Symptom**: Hub runs fine alone, crashes when game server connects with players
**Root Cause**: Hub v0.0.8 has timing issues when handling rapid connections
**Solution**: 
- Start Hub first, wait 5+ seconds before starting game server
- Ensure Hub fully initializes (check for "Discord:Gateway Ready" in logs)
- Updated `restart_all.sh` to add verification steps and longer waits

### 2. Port 5085 Already in Use
**Symptom**: Hub fails to start with "address already in use" error
**Root Cause**: Previous Hub process not properly killed during restart
**Solution**:
- Added `pkill -9 -f "AssettoServer.Hub"` to restart script
- Force kill ALL Hub processes before starting new one
- Added verification step to confirm processes stopped

### 3. Multiple Hub Instances Running
**Symptom**: Multiple Hub processes with same port causing conflicts
**Root Cause**: `stop_hub.sh` only kills PID from file, not all instances
**Solution**:
- Added pattern-based killing: `pkill -9 -f "AssettoServer.Hub"`
- Kills all Hub processes regardless of PID file
- Wait 2 seconds after kill to ensure ports freed

### 4. Hub Exits Silently Without Discord Bot Token
**Symptom**: Hub logs show startup then nothing, process dies
**Root Cause**: Hub v0.0.8 REQUIRES Discord bot token, exits silently without it
**Solution**:
- **Always** provide Discord bot token in `hub/configuration.yml`
- Token format: `DiscordBotToken: <your-token-here>`
- This is MANDATORY, not optional!

### 5. YAML Deserialization Error on Line 26
**Symptom**: "Exception during deserialization" when adding leaderboard templates
**Root Cause**: Incorrect YAML dictionary format for templates
**Solution**:
- Leave templates EMPTY: `DiscordOvertakeLeaderboardTemplates: {}`
- Templates are NOT required for basic leaderboard functionality
- Discord bot posts directly to channel, no webhook config needed

### 6. Game Server Crashes with "Error executing critical background service"
**Symptom**: Server crashes when Hub connection fails
**Root Cause**: PatreonHubPlugin enabled but Hub not running/reachable
**Solution**:
- ALWAYS start Hub before game server
- Verify Hub listening on port 5085: `ss -tlnp | grep 5085`
- Check Hub logs for "Ready" message before starting game server

### 7. Bot Token ASCII Character Error
**Symptom**: Accidentally typed `<` instead of `8` in bot token
**Root Cause**: Human error during copy/paste
**Solution**:
- Always copy-paste bot tokens directly from Discord Developer Portal
- Never manually type them
- Verify token format: `MTxxxxxxxxxx.xxxxxx.xxxxxxxxxxxxxxxxxxx`

## ✅ Proper Startup Sequence

```bash
# 1. Kill everything cleanly
./stop_hub.sh
./stop_server.sh
pkill -9 -f "AssettoServer"
sleep 2

# 2. Start Hub first
./start_hub.sh
sleep 5

# 3. Verify Hub ready
tail hub/hub.log | grep "Discord:Gateway Ready"
ss -tlnp | grep 5085  # Should show Hub listening

# 4. Start game server
./AssettoServer &
sleep 10

# 5. Verify connection
tail logs/log-$(date +%Y%m%d).txt | grep "Connected to AssettoServer Hub"
```

## 🔧 restart_all.sh Improvements

### Before:
```bash
./stop_hub.sh
pkill -f "[A]ssettoServer"  # Only game server, not Hub
sleep 1
./start_server.sh
```

### After:
```bash
./stop_hub.sh
pkill -9 -f "AssettoServer.Hub"  # Force kill Hub
pkill -9 -f "AssettoServer[^.]"  # Force kill game server (not Hub)
sleep 2

# Verification step
if pgrep -f "AssettoServer"; then
    echo "WARNING: Processes still running!"
    pkill -9 -f "AssettoServer"
    sleep 2
fi

./start_server.sh
```

### Key Changes:
1. **Force kill (`-9`)** instead of graceful kill
2. **Pattern matching** to differentiate Hub from game server
3. **Verification step** to ensure clean state
4. **Longer waits** (2 seconds instead of 1)
5. **Better process cleanup** before restart

## 📋 Configuration Checklist

### Hub Config (`hub/configuration.yml`)
- [ ] `DiscordBotToken` is set (MANDATORY!)
- [ ] `GrpcPort: 5085` matches game server config
- [ ] `Keys` section has server key matching game server
- [ ] `DiscordOvertakeLeaderboardTemplates: {}` (empty = OK)

### Game Server Config (`cfg/extra_cfg.yml`)
- [ ] `PatreonHubPlugin` in `EnablePlugins` list
- [ ] `PatreonOvertakePlugin` in `EnablePlugins` list
- [ ] `!PatreonHubConfiguration` section with correct address/key
- [ ] `!PatreonOvertakeConfiguration` has `LeaderboardName: RedLine Souls`

### Discord Bot Setup
- [ ] Bot created in Discord Developer Portal
- [ ] `Server Members Intent` enabled
- [ ] Bot added to your Discord server
- [ ] Bot has `Send Messages` permission in #leaderboard channel

## 🎯 Key Lessons

1. **Hub NEEDS Discord bot token** - Will exit silently without it
2. **Start order matters** - Always Hub first, then game server
3. **Wait times critical** - Don't rush, let Hub fully initialize
4. **Force kill required** - Graceful shutdown doesn't work reliably
5. **Verify before start** - Check ports and processes before starting new ones
6. **Templates optional** - Discord bot posts directly, webhooks not needed for basic use
7. **Pattern-based pkill** - More reliable than PID files

## 📖 Documentation Created

1. `DISCORD_LEADERBOARD_SETUP.md` - How to use `/overtake-leaderboard` command
2. `PATREON_PLUGINS_GUIDE.md` - Original setup guide
3. `HUB_SETUP_COMPLETE.md` - Hub installation notes
4. This file - Issues and solutions reference

---

**Summary**: Hub v0.0.8 is functional but requires careful startup sequencing and mandatory Discord bot token. Templates are optional. Game server connections must happen AFTER Hub is fully ready.
