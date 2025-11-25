# 🎮 Patreon Plugins & Hub Setup - Complete!

## ✅ What's Working

### Installed & Running:
1. **AssettoServer Hub v0.0.8** - Central leaderboard/data server
   - Location: `/home/acserver/server/hub/`
   - gRPC Port: 5085 (for game server connection)
   - HTTP Port: 8000 (web interface)
   - Key: `P52QBOKRegc2p5HapwC9JjIZO1g3tZ8R5Qe/02NVlJc=`

2. **Patreon Plugins v0.0.39** - All 10 plugins installed
   - ✅ PatreonHubPlugin - ENABLED & CONNECTED
   - ✅ PatreonOvertakePlugin - ENABLED & CONFIGURED
   - PatreonSpeedTrapPlugin - Ready to enable
   - 7 other plugins available

3. **License Key** - `patreon.key` verified and working

### Server Configuration (`extra_cfg.yml`):
```yaml
EnablePlugins:
  - RandomWeatherPlugin
  - PatreonHubPlugin  # Connects to Hub
  - PatreonOvertakePlugin  # Tracks overtakes

---
!PatreonHubConfiguration
Address: http://localhost:5085
Key: P52QBOKRegc2p5HapwC9JjIZO1g3tZ8R5Qe/02NVlJc=

---
!PatreonOvertakeConfiguration
LeaderboardName: RedLine Souls
MinimumSpeedKph: 80
TooSlowTimeoutSeconds: 3
OvertakeDistanceMeters: 7
CloseOvertakeDistanceMeters: 4
EnableUIByDefault: true
CollisionMessages:
  - Collision!
  - Watch out!
  - Careful!
OvertakeMessages:
  - Nice overtake!
  - Clean pass!
  - Smooth!
CloseOvertakeMessages:
  - Close one!
  - Near miss!
  - That was tight!
```

## 🚀 How to Use

### Starting/Stopping:
```bash
# Start everything (Hub + Game Server)
./start_server.sh

# Stop everything
./stop_server.sh

# Hub only
./start_hub.sh
./stop_hub.sh
```

### Check Status:
```bash
# Hub logs
tail -f hub/hub.log

# Game server connection
tail -f logs/log-$(date +%Y%m%d).txt | grep -i hub

# Check if Hub is running
ps aux | grep AssettoServer.Hub
```

## 📊 Features Now Active

### In-Game (Client-Side):
- **Overtake UI** - Shows score, multiplier, overtakes in real-time
  - Toggle with lightbulb icon in chat
  - Gain points for overtaking traffic
  - 3x multiplier for close overtakes
  - Collision resets your run

### Server-Side:
- **Leaderboard Tracking** - All overtake data saved to Hub database
- **Statistics** - Player rankings, scores, best runs

## 🎯 Next Steps for Discord Integration

###  Option 1: Discord Bot (Full Leaderboards)

**Requires:** Creating a Discord bot application

**Steps:**
1. Go to https://discord.com/developers/applications/
2. Create New Application → Name it "RedLine Souls Hub"
3. Bot → Add Bot → Copy Token
4. Add to `hub/configuration.yml`:
   ```yaml
   DiscordBotToken: "YOUR_BOT_TOKEN_HERE"
   ```
5. Restart Hub
6. Invite bot to your Discord server
7. Use slash commands:
   - `/overtake-leaderboard` - Shows top overtake players
   - `/server-status` - Shows server info

### Option 2: Speed Trap Webhooks (Quick & Easy)

**Uses:** Your existing Discord webhooks

**Add to `extra_cfg.yml`:**
```yaml
EnablePlugins:
  - RandomWeatherPlugin
  - PatreonHubPlugin
  - PatreonOvertakePlugin
  - PatreonSpeedTrapPlugin  # ADD THIS

---
!PatreonSpeedTrapConfiguration
NumberOffset: 100
EnablePictures: true
EnableOverlay: true
Grayscale: true
DiscordWebhook:
  Url: https://discord.com/api/webhooks/1427462778075218015/QRjTkpivsX_UgX7NhPP6-i3l4p5gPIMuYTCgqflG0Y5XF-PTpbpm0tZ_WY6lFex8jH3l
  Username: 速度違反自動取締装置
  MessageTemplate: |
    番号　{{ SpeedTrapId | math.format "000" }}・{{ Counter | math.format "000" }}
    違反者　{{ Name }}
    速度　{{ Speed | math.format "0" }}km/h
```

This will post speed trap violations with pictures to your Discord stats channel!

## 📁 File Locations

```
/home/acserver/server/
├── hub/                           # AssettoServer Hub
│   ├── AssettoServer.Hub         # Hub executable
│   ├── configuration.yml         # Hub config
│   ├── Hub.db                    # Leaderboard database (SQLite)
│   ├── hub.log                   # Hub logs
│   └── patreon.key               # License key (copy)
├── plugins/
│   ├── PatreonHubPlugin/
│   ├── PatreonOvertakePlugin/
│   │   └── lua/overtake.lua      # Client-side UI script
│   ├── PatreonSpeedTrapPlugin/
│   └── ... (7 more plugins)
├── cfg/
│   └── extra_cfg.yml             # Plugin configurations
├── patreon.key                   # License key (original)
├── start_server.sh               # Start everything
├── stop_server.sh                # Stop everything
├── start_hub.sh                  # Hub only
└── stop_hub.sh                   # Stop Hub

```

## 🌐 Web Interface

**URL:** `http://YOUR_SERVER_IP:8000`
- View leaderboards
- Manage players
- Server status

## ⚠️ Important Notes

1. **Hub must start before game server** - `start_server.sh` now does this automatically
2. **Database location** - `hub/Hub.db` contains all leaderboard data
3. **Backup** - Back up `Hub.db` to preserve leaderboard history
4. **Port 8000** - May need to open in firewall for web interface access

## 🐛 Troubleshooting

### Server won't start:
```bash
# Check Hub is running
ps aux | grep AssettoServer.Hub

# Restart Hub
./stop_hub.sh && ./start_hub.sh

# Check config syntax
grep -A 20 "PatreonHub" cfg/extra_cfg.yml
```

### Overtakes not tracking:
- Client needs CSP 0.1.77+ (1937)
- Check in-game: Lightbulb icon → Enable overtake UI
- Drive >80km/h and overtake traffic cars

### Leaderboard not updating:
- Verify Hub connection: `tail -f logs/log-$(date +%Y%m%d).txt | grep Hub`
- Check Hub database: `ls -lh hub/Hub.db`

## 📚 Documentation

- Patreon Plugins: https://assettoserver.org/patreon-docs/category/plugins/
- Hub Docs: https://assettoserver.org/patreon-docs/assettoserver-hub/
- Discord Bot Setup: https://assettoserver.org/patreon-docs/assettoserver-hub/discord

---

**Status:** ✅ Hub running, game server connected, overtake tracking active!

**Next:** Choose Discord integration method (bot or webhooks) and I'll help you configure it!
