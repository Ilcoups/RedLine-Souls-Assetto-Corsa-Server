# RedLine Souls - Running Services Checklist

This document lists ALL services and components that should be running on the server.

## Core Services (CRITICAL - Must be running)

### 1. AssettoServer (Game Server)
- **Process**: `./AssettoServer`
- **Check**: `pgrep -f "AssettoServer$"`
- **Ports**: 9600 (game), 8081 (HTTP API)
- **Logs**: `logs/log-YYYYMMDD.txt`
- **Started by**: `start_server.sh`

### 2. AssettoServer.Hub
- **Process**: `./AssettoServer.Hub`
- **Check**: `pgrep -f "AssettoServer.Hub"`
- **Ports**: 5085 (gRPC), 8000 (Web UI)
- **Logs**: `hub/logs/hub-YYYYMMDD.txt`
- **Started by**: `start_server.sh` (or manually)
- **Critical**: Must start BEFORE game server

### 3. player_stats.py
- **Process**: `python3 -u player_stats.py`
- **Check**: `pgrep -f "player_stats.py"`
- **Purpose**: Tracks player statistics, posts daily leaderboards
- **Logs**: `stats_tracker.log`
- **Started by**: `start_server.sh`
- **Schedule**: Posts at 23:50 UTC (connection stats) and 23:59 UTC (leaderboard)

### 4. unified_announcer.service (systemd)
- **Service**: `unified-announcer.service`
- **Check**: `systemctl --user status unified-announcer.service`
- **Purpose**: Discord notifications, in-game chat relay, spawn audio
- **Logs**: `journalctl --user -u unified-announcer.service`
- **Started by**: systemd user service (auto-restart enabled)
- **Config**: `.env` (webhooks)

### 5. dynamic_traffic.py
- **Process**: `python3 dynamic_traffic.py --monitor`
- **Check**: `pgrep -f "dynamic_traffic.py"`
- **Purpose**: 6-hour traffic rotations + player count auto-scaling
- **Logs**: `logs/dynamic_traffic.log`
- **Started by**: `start_server.sh` or manually
- **Features**:
  - Traffic presets (night/morning/afternoon/evening)
  - Player count auto-scaling (30% reduction at 21-25 players)
  - Poll-based analysis (suggestions for tuning)

### 6. Audio HTTP Server
- **Process**: `python3 -m http.server 8082 --directory wwwroot`
- **Check**: `pgrep -f "http.server 8082"`
- **Port**: 8082
- **Purpose**: Serves spawn audio files for CSP
- **Started by**: `start_server.sh`

---

## Plugins (CRITICAL - Must be loaded)

### 1. PatreonHubPlugin
- **Status**: Check `grep "PatreonHubPlugin" cfg/extra_cfg.yml`
- **Purpose**: Connects game server to Hub
- **Verify**: Look for "Connected to AssettoServer Hub" in logs

### 2. RandomWeatherPlugin
- **Status**: Check `grep "RandomWeatherPlugin" cfg/extra_cfg.yml`
- **Purpose**: Dynamic weather transitions

### 3. PatreonOvertakePlugin
- **Status**: Check `grep "PatreonOvertakePlugin" cfg/extra_cfg.yml`
- **Purpose**: Overtake tracking (personal bests)

### 4. PatreonSpeedTrapPlugin
- **Status**: Check `grep "PatreonSpeedTrapPlugin" cfg/extra_cfg.yml`
- **Purpose**: Speed violation detection

### 5. PatreonTimingPlugin
- **Status**: Check `grep "PatreonTimingPlugin" cfg/extra_cfg.yml`
- **Purpose**: Lap timing and leaderboards

### 6. DiscordAuditPlugin
- **Status**: Check `grep "DiscordAuditPlugin" cfg/extra_cfg.yml`
- **Purpose**: Server audit events to Discord
- **Config**: `cfg/plugin_discord_audit_cfg.yml`

### 7. PatreonAnalyticsPlugin (NEWEST)
- **Status**: Check `grep "PatreonAnalyticsPlugin" cfg/extra_cfg.yml`
- **Purpose**: Player FPS, CPU, collision metrics
- **Verify**: `curl http://127.0.0.1:8081/metrics | grep assettoserver`
- **Config**: `!PatreonAnalyticsConfiguration` in `extra_cfg.yml`

---

## Discord Integrations

### 1. Main Webhook (Join/Leave Messages)
- **Env Var**: `DISCORD_WEBHOOK`
- **Used by**: `unified_announcer.py`
- **Posts**: Player join, leave, session summaries, checksum failures

### 2. Stats Webhook (#daily-statistic)
- **Env Var**: `DISCORD_STATS_WEBHOOK`
- **Used by**: `player_stats.py`
- **Posts**: Daily leaderboards (23:59 UTC), connection statistics (23:50 UTC)
- **NEW**: Traffic poll results with visual bar charts

### 3. Chat Webhook (#chat-eu-1)
- **Env Var**: `DISCORD_CHAT_WEBHOOK`
- **Used by**: `unified_announcer.py`
- **Posts**: In-game chat messages from players
- **NEW**: Handles /1 through /5 traffic poll votes

### 4. Audit Webhook (#servers) (Optional)
- **Env Var**: `DISCORD_AUDIT_WEBHOOK`
- **Used by**: `DiscordAuditPlugin`
- **Config**: `cfg/plugin_discord_audit_cfg.yml`
- **Posts**: Server connections, disconnections, status updates

### 5. Hub Discord Bot
- **Config**: `hub/configuration.yml` (`DiscordBotToken`)
- **Purpose**: `/server-status` command for live server info
- **Verify**: Look for "[Discord:Gateway] Ready" in Hub logs

---

## Auto-Scaling Systems (NEW!)

### 1. Player Count Auto-Scaling
- **Implemented in**: `dynamic_traffic.py`
- **Check interval**: Every 5 minutes
- **Purpose**: Reduces AI traffic when server is crowded to prevent lag
- **Thresholds**:
  - 0-10 players: 100% AI (full traffic)
  - 11-15 players: 85% AI
  - 16-20 players: 75% AI
  - 21-25 players: 70% AI (30% reduction!)
  - 26+ players: 65% AI (maximum reduction)
- **Status**: ✅ ACTIVE
- **Verify**: `grep "👥 Current Players" logs/dynamic_traffic.log`

### 2. Weighted Traffic Poll System
- **Implemented in**: `unified_announcer.py`
- **Trigger**: After 10 minutes of play
- **Vote commands**: `/1` (worst) to `/5` (best)
- **Vote weighting**:
  - 10 min session = 0.33x weight
  - 30 min session = 1.00x weight (baseline)
  - 60 min session = 2.00x weight
  - 120+ min session = 3.00x weight (capped)
- **Regular player badge**: ⭐ (2+ hours total, 3+ sessions)
- **Data file**: `traffic_votes.json`
- **Status**: ✅ ACTIVE
- **Verify**: `grep "Poll:" logs/unified_announcer.log`

### 3. Poll-Based Analysis
- **Implemented in**: `dynamic_traffic.py`
- **Purpose**: Analyzes poll data, suggests traffic adjustments
- **Requirements**: 5+ votes, 8.0+ weighted votes, 3+ days
- **Status**: ✅ ACTIVE (suggestions only, manual changes)
- **CLI**: `python3 dynamic_traffic.py --poll-analysis`
- **Future**: Phase 2 will enable auto-tuning

---

## Hub Features

### 1. Server Status Widget
- **Config**: `hub/configuration.yml` → `DiscordServerStatus`
- **Widget ID**: `redline-tokyo`
- **Command**: `/server-status redline-tokyo`
- **Shows**: Online/offline, player count, time, join button

### 2. Hub Database
- **File**: `hub/Hub.db`
- **Purpose**: Stores leaderboards, player data, timing records

---

## Endpoints & Ports

| Port | Service | Purpose | Check |
|------|---------|---------|-------|
| 9600 | Game Server (TCP/UDP) | Game traffic | `lsof -i :9600` |
| 8081 | HTTP API (TCP) | Server details, /metrics | `curl http://127.0.0.1:8081/api/details` |
| 8082 | Audio Server (TCP) | Spawn audio files | `curl http://127.0.0.1:8082/` |
| 5085 | Hub gRPC (TCP) | Game server ↔ Hub | `lsof -i :5085` |
| 8000 | Hub Web UI (TCP) | Hub web interface | `curl http://127.0.0.1:8000/` |
| 12000 | UDP Plugin | In-game chat relay | Internal |

---

## Critical Files & Permissions

### Configuration Files
- `cfg/server_cfg.ini` - Server settings (GITIGNORED)
- `cfg/extra_cfg.yml` - Plugins, AI, weather, server description
- `cfg/plugin_discord_audit_cfg.yml` - Audit plugin webhook
- `hub/configuration.yml` - Hub settings, Discord bot
- `.env` - Webhooks (GITIGNORED, must be 600 permissions)

### Data Files
- `player_stats.json` - Player statistics persistence (GITIGNORED)
- `hub/Hub.db` - Hub database (GITIGNORED)
- `traffic_votes.json` - Traffic poll votes (NEW, GITIGNORED)

### Log Files (GITIGNORED)
- `logs/log-YYYYMMDD.txt` - Game server logs
- `hub/logs/hub-YYYYMMDD.txt` - Hub logs
- `stats_tracker.log` - player_stats.py logs
- `logs/unified_announcer.log` - Announcer logs (or journalctl)

---

## Quick Health Check Commands

```bash
# Check all processes
ps aux | grep -E "AssettoServer|player_stats|http.server|unified"

# Check systemd service
systemctl --user status unified-announcer.service

# Check all ports
lsof -i :9600 -i :8081 -i :8082 -i :5085 -i :8000

# Check Hub connection
grep "Connected to AssettoServer Hub" logs/log-$(date +%Y%m%d).txt

# Check Discord bot
grep "Discord:Gateway.*Ready" hub/hub.log

# Check analytics
curl -s http://127.0.0.1:8081/metrics | grep assettoserver

# Run full test suite
cd tests && ./run_tests.sh
```

---

## Startup Order (CRITICAL)

1. **AssettoServer.Hub** (MUST start first)
   - Wait for Discord bot: "[Discord:Gateway] Ready"
   - Wait 3-5 seconds for full initialization

2. **Game Server** (`./AssettoServer`)
   - Will connect to Hub via gRPC (port 5085)
   - Look for "Connected to AssettoServer Hub"

3. **Helper Scripts** (can start in parallel)
   - `player_stats.py`
   - Audio HTTP server

4. **Systemd Service** (independent)
   - `unified-announcer.service` (auto-starts, auto-restarts)

---

## What to Check After Restart

1. ✅ All 5 processes running
2. ✅ All 5 ports listening
3. ✅ Hub connected to Discord
4. ✅ Game server connected to Hub
5. ✅ All 7 plugins loaded
6. ✅ Analytics /metrics endpoint responding
7. ✅ All 3-4 webhooks configured in .env
8. ✅ No errors in recent logs
9. ✅ .env file permissions = 600

**Run the automated test suite:**
```bash
cd /home/acserver/server && ./tests/run_tests.sh
```

---

**Last Updated**: 2025-11-09  
**Maintainer**: See `server/CLAUDE.md` for technical details

