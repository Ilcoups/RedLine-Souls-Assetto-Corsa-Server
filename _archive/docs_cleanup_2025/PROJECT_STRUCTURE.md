# RedLine Souls - Project Structure

## 📁 Directory Layout

```
/home/acserver/server/
├── 🎮 AssettoServer          # Main server executable
├── ⚙️  cfg/                   # Server configuration
├── 📜 *.sh                    # Main startup/control scripts
├── 🐍 *.py                    # Active Python scripts
│
├── 📚 _docs/                  # ALL DOCUMENTATION
├── 📦 _archive/               # Old/replaced files (do not use)
├── 🔧 _utils/                 # Utilities & test scripts
│
├── 🌐 wwwroot/                # HTTP content (audio, CSP scripts)
├── 📊 logs/                   # Server logs
├── 🔌 plugins/                # AssettoServer plugins
└── 🎨 content/                # Game content
```

---

## 🚀 Active Files (Root Directory)

### Startup Scripts:
- **`restart_for_audio.sh`** ⭐ - MAIN restart script (everything at once)
- **`start_server.sh`** - Start server + announcer + stats
- **`stop_server.sh`** - Stop server
- **`start_audio_server.sh`** - Start HTTP server for audio files

### Active Python Scripts:
- **`unified_announcer.py`** ⭐ - Discord + Chat + Audio (currently active)
- **`player_stats.py`** - Player statistics tracker
- **`udp_announcer.py`** - UDP announcer (check if redundant!)

### Services:
- **`unified-announcer.service`** - Systemd service for announcer

---

## 📚 Documentation (_docs/)

### Main Documentation:
- **`README.md`** - Project overview
- **`FIXES_APPLIED.md`** ⭐ - Summary of all fixes
- **`START_HERE.md`** - Quick start guide

### Fix Documentation (chronological):
1. **`TRAFFIC_UPGRADE.md`** - Traffic upgrade (speed, density)
2. **`TRAFFIC_BALANCE_FIX.md`** - Speed balancing per lane
3. **`DISCORD_FIX.md`** - Fixed Discord duplicates
4. **`RATE_LIMIT_FIX.md`** - Rate limiting for checksum spam
5. **`AUDIO_FIX.md`** - HTTP server fix for audio

### Other:
- **`SPAWN_AUDIO_SETUP.md`** - Spawn audio configuration
- **`IMPLEMENTATION_COMPLETE.md`** - Implementation details
- **`README_STEAM.md`** - Steam-specific information

---

## 📦 Archive (_archive/)

### old_scripts/ - Replaced Scripts:
- `full_announcer.py` → replaced by `unified_announcer.py`
- `spawn_audio_trigger.py` → replaced by `unified_announcer.py`
- `start_announcer.sh` → replaced by `restart_for_audio.sh`
- `start_spawn_audio.sh` → replaced by `restart_for_audio.sh`
- `start_webhooks.sh` → replaced by `restart_for_audio.sh`
- `discord-webhooks.service` → replaced by `unified-announcer.service`
- `spawn-audio.service` → replaced by `unified-announcer.service`

**⚠️ Do NOT use these scripts! Outdated but preserved for reference.**

---

## 🔧 Utilities (_utils/)

### Shell Scripts:
- `change_weather.sh` - Change weather conditions
- `server_status.sh` - Check server status
- `stats_tracker.sh` - Statistics tracker

### Python Utilities:
- `test_leaderboard.py` - Leaderboard testing
- `test_rcon.py` - RCON connection testing
- `filelock.py` - File locking utility
- `steampipe_fixups.py` - Steam pipe fixes

---

## ⚙️ Configuration (cfg/)

```
cfg/
├── server_cfg.ini              # Main server config
├── extra_cfg.yml               # ⭐ AI traffic, plugins, weather
├── csp_extra_options.ini       # CSP settings (spawn audio script)
├── entry_list.ini              # AI car list
├── welcome.txt                 # Welcome message
└── data_track_params.ini       # Track parameters
```

**⚠️ Main files to edit:**
- `extra_cfg.yml` - traffic, speeds, plugins
- `server_cfg.ini` - ports, server name
- `entry_list.ini` - AI cars

---

## 🌐 wwwroot/ - HTTP Content

```
wwwroot/
├── audio/
│   └── RedLineSoulsIntro.ogg   # Spawn audio file
└── csp_scripts/
    └── spawn_audio.lua          # CSP Lua script
```

**Port 8082** - Python HTTP server serves these files

---

## 📊 logs/ - Server Logs

```
logs/
├── log-YYYYMMDD.txt            # Main server log
├── server_console.log          # Console output
├── unified_announcer.log       # Announcer log
└── unified_announcer_error.log # Announcer errors
```

---

## 🎯 What to Use

### ✅ USE THESE:
- `restart_for_audio.sh` - for server restarts
- `unified_announcer.py` - for Discord/Chat/Audio
- `_docs/` - for documentation
- `cfg/extra_cfg.yml` - for traffic configuration

### ❌ DON'T USE:
- `_archive/old_scripts/*` - all replaced!
- `full_announcer.py` - outdated
- `spawn_audio_trigger.py` - outdated

### ❓ CHECK:
- `udp_announcer.py` - might be duplicate of unified_announcer?

---

## 🚦 Quick Commands

```bash
# Restart everything (server + announcer + audio HTTP)
./restart_for_audio.sh

# View logs
tail -f logs/log-$(date +%Y%m%d).txt
tail -f logs/unified_announcer.log

# Check processes
ps aux | grep -E "(AssettoServer|unified_announcer|http.server)"

# Test audio accessibility
curl -I http://localhost:8082/audio/RedLineSoulsIntro.ogg
```

---

## 📝 Changelog

**2025-10-15:**
- ✅ Organized project structure (_docs, _archive, _utils folders)
- ✅ Unified announcer (replaced 3 scripts)
- ✅ Fixed traffic (speeds, bouncing)
- ✅ Fixed Discord spam
- ✅ Fixed spawn audio (HTTP server)
- ✅ Rate limiting for checksum failures

---

## 💡 Useful Links

- **All fixes:** `_docs/FIXES_APPLIED.md`
- **Traffic settings:** `cfg/extra_cfg.yml` + `_docs/TRAFFIC_*.md`
- **Discord setup:** `_docs/DISCORD_FIX.md`
- **Audio setup:** `_docs/AUDIO_FIX.md`

---

**Project organized ✨ Nothing deleted, everything structured!**
