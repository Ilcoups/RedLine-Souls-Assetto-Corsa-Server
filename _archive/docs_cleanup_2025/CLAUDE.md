# CLAUDE.md - AI Assistant Documentation

This file contains technical context for AI assistants (Claude, GPT, etc.) helping developers work on this Assetto Corsa server.

---

## 🤖 For AI Assistants: Project Context

### What This Project Is
- **RedLine Souls** - AssettoServer-based multiplayer server
- **Track**: Shuto Revival Project Beta (Tokyo expressway recreation)
- **Focus**: High-speed AI traffic cruising with Discord integration
- **Platform**: Linux (Ubuntu/Debian), user: `acserver` (NOT root)

---

## 🏗️ Architecture

### Core Components

1. **AssettoServer** (C#/.NET)
   - Main game server binary (`./AssettoServer`)
   - Config: `cfg/extra_cfg.yml`, `cfg/server_cfg.ini`
   - Logs: `logs/log-YYYYMMDD.txt`

2. **unified_announcer.py** (Python 3)
   - Discord webhooks (join/leave/session complete)
   - UDP chat messages to server
   - Spawn audio triggers
   - **Managed by systemd user service** (`~/.config/systemd/user/unified-announcer.service`)
   - Logs: `logs/unified_announcer.log`

3. **player_stats.py** (Python 3)
   - Tracks collisions, playtime, speeds
   - Posts daily leaderboard to Discord at 23:59 UTC
   - **Managed by start_server.sh** (manual process)
   - Logs: `stats_tracker.log`

4. **Audio HTTP Server** (Python 3 http.server)
   - Serves `wwwroot/` for CSP audio files
   - Port 8082
   - Started by `start_server.sh`

---

## 📂 File Structure (Important Paths)

```
/home/acserver/server/
├── AssettoServer               # Main server binary
├── cfg/
│   ├── extra_cfg.yml          # AI traffic, plugins, weather
│   ├── server_cfg.ini         # Network, admin password (GITIGNORED)
│   └── csp_extra_options.ini  # CSP features, spawn audio, teleports
├── unified_announcer.py        # Discord + Chat + Audio
├── player_stats.py            # Stats tracking + leaderboards
├── .env                       # Webhooks (GITIGNORED)
├── .env.example               # Template (SAFE to commit)
├── start_server.sh            # Main startup script
├── stop_server.sh             # Shutdown script
├── archive_old_logs.sh        # Log compression (keeps last 7 days)
├── logs/                      # Server logs (GITIGNORED)
│   └── archive/               # Compressed old logs (.gz)
├── wwwroot/                   # HTTP server root (audio files)
├── TELEPORTS.md               # Teleport system documentation
└── _docs/                     # Human documentation
```

---

## 🔑 Critical Technical Details

### Environment Variables (.env)
```bash
DISCORD_WEBHOOK="..."          # Player join/leave events
DISCORD_CHAT_WEBHOOK="..."     # Chat messages
DISCORD_STATS_WEBHOOK="..."    # Daily leaderboards
UDP_PLUGIN_HOST=127.0.0.1
UDP_PLUGIN_PORT=12001
```

**Loading mechanism**: Custom fallback loader in Python scripts (no `python-dotenv` dependency)
```python
# Both unified_announcer.py and player_stats.py use this
env_path = Path('/home/acserver/server/.env')
# Parse manually: k, v = line.split('=', 1)
```

### User Permissions
- **User**: `acserver` (NOT root, no sudo access)
- Can install Python packages: `pip3 install --user <package>`
- Can manage user systemd services: `systemctl --user <command>`
- **Cannot**: Install system packages, use sudo

### Systemd Service
```bash
# Service location
~/.config/systemd/user/unified-announcer.service

# Commands
systemctl --user status unified-announcer.service
systemctl --user restart unified-announcer.service
journalctl --user -u unified-announcer.service -f
```

---

## 🚗 AI Traffic Configuration

### Key Parameters (cfg/extra_cfg.yml)
```yaml
AiParams:
  PlayerAfkTimeoutSeconds: 5           # Traffic ignores AFK players after 5s
  IgnoreObstaclesAfterSeconds: 3       # Traffic drives through obstacles after 3s
  IgnoreStationaryPlayers: true        # Critical for no traffic jams
  MinCollisionStopTimeSeconds: 1       # Stop briefly for collisions
  MaxCollisionStopTimeSeconds: 2
  
  # Heiwajima PA pit area - traffic ignores ALL players here
  IgnorePlayerObstacleSpheres:
    - X: 1735.0
      Z: -1670.0
      Radius: 150.0
```

**Lane-specific overrides**: 3-lane highways = fastest, 1-lane = slowest

### Dynamic Traffic System
**Service**: `dynamic-traffic.service` (systemd user service)
**Script**: `/home/acserver/server/dynamic_traffic.py`

Features:
1. **6-Hour Preset Rotation** - Changes traffic style every 6 hours (night/morning/afternoon/evening)
2. **Player-Based Scaling** - Reduces AI count as player count increases (1-10 = 100%, 26+ = 65%)
3. **Idle Traffic** - **NEW!** Keeps 15 AI cars running with 0 players for instant join
4. **Server Load Monitoring** - Monitors CPU, memory, and system load every 60 seconds
5. **Emergency Scaling** - Automatically reduces AI to 50% during server stress
6. **Player Spike Detection** - Detects sudden player influx and monitors closely

**Idle Traffic** (0 players):
- 15 AI cars always running (keeps system warm)
- Instant join - no waiting for traffic to spawn
- Minimal resources (~0.2% CPU, ~50MB RAM)
- Configurable: `'idle_traffic_enabled': True`, `'idle_ai_count': 15`

**Load Monitoring Thresholds**:
- CPU: Warning 75%, Critical 85%, Recovery <60%
- Memory: Warning 2.5GB, Critical 3.5GB, Recovery <2.0GB
- Load Avg: Warning 3.0, Critical 3.5, Recovery <2.5

**Commands**:
```bash
python3 dynamic_traffic.py --schedule       # View all features
python3 dynamic_traffic.py --check-load     # Check server health
systemctl --user restart dynamic-traffic.service
journalctl --user -u dynamic-traffic.service -f
```

See `IDLE_TRAFFIC_FEATURE.md` and `SERVER_LOAD_MONITOR.md` for full documentation.

---

## 💬 Discord Message Editing

### How It Works
```python
# 1. Post join message with ?wait=true to get message ID
webhook_url += '?wait=true'
response = requests.post(webhook_url, json=data)
message_id = response.json().get('id')

# 2. Store message ID in active_sessions
active_sessions[steam_id] = {
    'discord_message_id': message_id,
    'join_time': datetime.now(timezone.utc),
    ...
}

# 3. Edit message when player leaves
edit_url = f"https://discord.com/api/webhooks/{id}/{token}/messages/{message_id}"
requests.patch(edit_url, json=data)
```

**Why `?wait=true` is critical**: Discord webhooks DON'T return message ID by default!

---

## 📊 Log Monitoring Pattern

### Both Python scripts use this pattern:
```python
last_position = 0
last_log_file = None

def monitor_logs():
    global last_position, last_log_file
    
    log_file = get_latest_log()  # logs/log-YYYYMMDD.txt
    
    if last_log_file != log_file:
        last_position = log_file.stat().st_size  # Start from end on rotation
        last_log_file = log_file
    
    with open(log_file, 'r', encoding='utf-8', errors='ignore') as f:
        f.seek(last_position)
        new_lines = f.readlines()
        last_position = f.tell()
        
        for line in new_lines:
            process_line(line)
```

---

## 🐛 Common Issues & Solutions

### Issue 1: Discord Messages Not Editing
**Symptom**: Two separate messages (join + leave) instead of one edited message
**Cause**: Missing `?wait=true` parameter
**Fix**: Always append to webhook URL before POST

### Issue 2: Traffic Jams at Heiwajima Pit
**Symptom**: AI traffic stops under pit bridge, creates пробка
**Solution**: Add `IgnorePlayerObstacleSpheres` for pit coordinates

### Issue 3: Environment Variables Not Loading
**Symptom**: `DISCORD_WEBHOOK` is None
**Check**: 
1. `.env` file exists in `/home/acserver/server/`
2. File has proper format: `KEY="value"` (quotes optional)
3. Fallback loader is working (check startup logs)

### Issue 4: NullReferenceException in HTTP Controller
**Symptom**: Spam in logs about `GetDetails(String guid)`
**Cause**: Content Manager requests without GUID
**Fix**: Set `AssettoServer.Network.Http: "Error"` in appsettings.json (hides noise)

### Issue 5: Duplicate Weather Entries
**Symptom**: Cold, Hot, Windy appear twice in WeatherWeights
**Fix**: Keep only first set, remove duplicates at bottom

---

## 🔄 Startup/Shutdown Flow

### Starting
```bash
./start_server.sh
# 1. Kills old processes (AssettoServer, player_stats)
# 2. Starts AssettoServer (nohup background)
# 3. Checks unified-announcer.service status
# 4. Starts player_stats.py (nohup background)
# 5. Starts audio HTTP server (port 8082) if not running
```

### Stopping
```bash
./stop_server.sh
# pkill -f AssettoServer (also kills audio server, player_stats)
# unified-announcer keeps running (systemd managed)
```

---

## 📝 Git Workflow

### Protected Files (NEVER commit)

### Safe to Commit
## Documentation Structure
All documentation is now organized in the `_docs/` folder:
- `_docs/guides/` for user and admin guides
- `_docs/audits/` for server health, stress, and analysis reports
- `_docs/features/` for feature explanations and proposals
- `_docs/technical/` for technical references, licenses, and architecture

```
Fix: Brief description

Details:
- Bullet point changes
- With technical specifics
- And impact/results
```

---

## 🧪 Testing Commands

### Test Discord Join
```bash
python3 unified_announcer.py --test-join "TestPlayer" "76561199999999999" "ferrari_f40"
```

### Test Discord Summary
```bash
python3 unified_announcer.py --test-summary "TestPlayer" "76561199999999999" "ferrari_f40" 300
```

### Test Daily Leaderboard
```bash
python3 player_stats.py --test-summary-now
# Creates .test_summary_flag to prevent duplicates
```

### View Real-time Logs
```bash
# Server
tail -f logs/log-$(date +%Y%m%d).txt

# Announcer
journalctl --user -u unified-announcer.service -f

# Stats
tail -f stats_tracker.log
```

---

## 🎯 When Making Changes

### Modifying AI Traffic
1. Edit `cfg/extra_cfg.yml` → `AiParams` section
2. Restart server: `./stop_server.sh && ./start_server.sh`
3. Test with multiple players in different areas

### Modifying Discord Integration
1. Edit `unified_announcer.py`
2. Restart service: `systemctl --user restart unified-announcer.service`
3. Check logs: `journalctl --user -u unified-announcer.service -f`
4. Test with `--test-join` / `--test-leave` flags

### Modifying Statistics
1. Edit `player_stats.py`
2. Kill old process: `pkill -f player_stats`
3. Restart: `nohup python3 player_stats.py > stats_tracker.log 2>&1 &`
4. Test: `python3 player_stats.py --test-summary-now`

### Modifying Weather
1. Edit `cfg/extra_cfg.yml` → `!RandomWeatherConfiguration`
2. Restart server (changes apply on next weather transition)
3. Check logs for "Random weather transitioning to..."

---

## 🔧 Maintenance Tasks

### Archive Old Logs
```bash
./archive_old_logs.sh
# Keeps last 7 days, compresses older to logs/archive/*.gz
```

### Check Service Status
```bash
systemctl --user status unified-announcer.service
ps aux | grep player_stats
ps aux | grep "http.server 8082"
```

### Clean Test Flags
```bash
rm -f .test_announcer_flag .test_summary_flag
```

---

## 💡 Design Decisions (Why Things Are This Way)

### Why systemd for announcer but not stats?
- **Announcer**: Critical for notifications, needs auto-restart, runs 24/7
- **Stats**: Can tolerate downtime, restarted with server anyway

### Why custom .env loader instead of python-dotenv?
- No sudo access = can't install system packages easily
- Avoid dependencies for simple key=value parsing
- Works everywhere, no pip install needed

### Why ?wait=true for Discord?
- Webhook POST normally returns 204 (no content)
- Need message ID to edit later
- `?wait=true` forces 200 + JSON response with ID

### Why IgnoreStationaryPlayers is critical?
- Players AFK in pits block AI spline
- Without this: traffic stops → chain reaction → massive jam
- With this: traffic flows through parked cars after timeout

### Why archive logs instead of delete?
- Debug historical issues
- gzip compression: 17MB → 472KB (97% reduction!)
- No external packages needed (gzip is built-in)

### Why Teleport System?
- 157 locations covering entire SRP 0.9.3 map
- Integrated via `csp_extra_options.ini` (CSP standard format)
- No server restart needed - CSP loads config on connect
- Credits: [Gaulven's teleport pack](https://discord.gaulven.com/)
- Covers C1 Inner/Outer, all routes (3, 4, 6, 9, 11, B, K1, K3, K5, Y)
- Includes famous spots: Shibuya, Daikoku, Tatsumi PA, etc.

---

## 🚨 Red Flags (What NOT to Do)

❌ **DON'T** commit `.env` or `cfg/server_cfg.ini`
❌ **DON'T** run scripts as root/sudo
❌ **DON'T** install system packages (no sudo access)
❌ **DON'T** edit files in `_archive/` (old/deprecated)
❌ **DON'T** post Discord webhooks without rate limiting
❌ **DON'T** hardcode credentials in Python files
❌ **DON'T** forget `?wait=true` for Discord message editing
❌ **DON'T** set `PlayerAfkTimeoutSeconds` > 10 (traffic jams!)

---

## ✅ Best Practices

✅ **DO** use environment variables for all credentials
✅ **DO** add error handling with try/except in Python
✅ **DO** check systemd service status before manual starts
✅ **DO** test Discord integrations with --test flags
✅ **DO** restart server after AI traffic changes
✅ **DO** archive logs before they fill disk
✅ **DO** use semantic commit messages
✅ **DO** keep README.md user-friendly (this file is for AIs!)

---

## 📚 External Resources

- [AssettoServer Docs](https://assettoserver.org/docs)
- [Discord Webhook Guide](https://discord.com/developers/docs/resources/webhook)
- [SRP Track Discord](https://discord.gg/shutokorevivalproject)
- [CSP Documentation](https://acstuff.ru/patch/)

---

## 🔮 Future Improvements (Ideas)

- [ ] Migrate player_stats.py to systemd service
- [ ] Add health check endpoint for monitoring
- [ ] Implement webhook retry logic with exponential backoff
- [ ] Create unified config validator script
- [ ] Add auto-archive cron job for logs
- [ ] Implement graceful shutdown handler

---

**Last Updated**: November 1, 2025
**Maintained by**: AI assistants helping developers on this project
**Human-friendly docs**: See `README.md` and `_docs/` folder
