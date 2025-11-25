# 🎮 Patreon Plugins Setup Guide

## Overview

You have **10 Patreon plugins** installed (v0.0.39). Most plugins require **AssettoServer Hub** to work properly, especially for Discord leaderboards.

## 📦 What You Have

### Installed Plugins
1. ✅ **PatreonOvertakePlugin** - ENABLED
2. **PatreonAnalyticsPlugin** - Available
3. **PatreonChatRolesPlugin** - Available
4. **PatreonHubPlugin** - Available (needs Hub server)
5. **PatreonRaceChallengePlugin** - Available
6. **PatreonReservedSlotsPlugin** - Available
7. **PatreonSafetyRatingPlugin** - Available
8. ✅ **PatreonSpeedTrapPlugin** - Can work standalone with Discord webhooks!
9. **PatreonTimingPlugin** - Available
10. **PatreonTwitchChatPlugin** - Available

## 🎯 Two Approaches

### Option 1: Speed Traps (Easy - No Hub Required!)

**PatreonSpeedTrapPlugin** can post directly to Discord without Hub!

#### Setup:
1. Enable plugin in `extra_cfg.yml`
2. Add configuration to `extra_cfg.yml`:

```yaml
---!PatreonSpeedTrapConfiguration
NumberOffset: 100
EnablePictures: true
EnableOverlay: true
Grayscale: true
AllowDisablingPictureUpload: true
Debug: false
DiscordWebhook:
  Url: YOUR_DISCORD_WEBHOOK_URL
  Username: 速度違反自動取締装置
  PictureUrl: https://assettoserver.org/img/logo.svg
  MessageTemplate: |
    番号　{{ SpeedTrapId | math.format "000" }}・{{ Counter | math.format "000" }}
    違反者　{{ Name }}
    速度　{{ Speed | math.format "0" }}km/h
    制限速度　{{ AllowedSpeed }}km/h
```

**Benefits:**
- Works immediately with your existing Discord webhook
- Posts speed trap violations with images to Discord
- No additional software needed
- Perfect for SRP servers

### Option 2: Full Leaderboards (Advanced - Requires Hub)

For **Overtake Leaderboards**, **Timing Leaderboards**, and **Safety Rating**, you need **AssettoServer Hub**.

#### What is AssettoServer Hub?

A separate server application that:
- Centralizes leaderboard data from multiple game servers
- Has a Discord bot for `/overtake-leaderboard` commands
- Provides web interface for viewing stats
- Stores data in SQLite database

#### Requirements:
1. Download AssettoServer Hub from Patreon (separate download from plugins)
2. Run Hub on this server (or another server)
3. Configure Hub with Discord bot token
4. Connect your game server to Hub

#### Hub Setup Steps:

**1. Download Hub**
- Check your Patreon downloads for "AssettoServer.Hub"
- Extract to `/home/acserver/hub/` (recommended)

**2. First Run (generates config)**
```bash
cd /home/acserver/hub
./AssettoServer.Hub
# Ctrl+C after it generates configuration.yml
```

**3. Configure Hub** (`configuration.yml`):
```yaml
GrpcPort: 5085
HttpPort: 8000
HubName: RedLine Souls Hub
Keys:
  - Name: redline-server-1

# Optional: Discord Bot for leaderboards
DiscordBotToken: "YOUR_BOT_TOKEN_HERE"
```

**4. Create Discord Bot** (for leaderboards):
- Visit https://discord.com/developers/applications/
- Create New Application
- Bot → Add Bot
- Enable "Server Members Intent"
- Copy token to `configuration.yml`
- OAuth2 → URL Generator → Select `bot` → Permissions: Send Messages, Manage Roles
- Invite bot to your Discord server

**5. Start Hub**
```bash
cd /home/acserver/hub
./AssettoServer.Hub
```

**6. Configure Game Server** (`extra_cfg.yml`):
```yaml
EnablePlugins:
  - RandomWeatherPlugin
  - PatreonOvertakePlugin
  - PatreonHubPlugin

---!PatreonHubConfiguration
Address: http://localhost:5085
Key: YOUR_GENERATED_KEY_FROM_HUB_CONFIG

---!PatreonOvertakeConfiguration
LeaderboardName: RedLine Souls
MinimumSpeedKph: 80
TooSlowTimeoutSeconds: 3
OvertakeDistanceMeters: 7
CloseOvertakeDistanceMeters: 4
EnableUIByDefault: true
CollisionMessages:
  - Collision!
  - Watch out!
OvertakeMessages:
  - Nice overtake!
CloseOvertakeMessages:
  - Close one!
  - Near miss!
```

**7. Discord Commands** (in your Discord server):
```
/overtake-leaderboard
/timing-points-leaderboard
/timing-stage-leaderboard
/server-status
```

## 🚀 Recommended Quick Start

**For immediate results, start with PatreonSpeedTrapPlugin!**

1. Add configuration to `extra_cfg.yml` (see Option 1 above)
2. Use your existing `DISCORD_STATS_WEBHOOK` URL
3. Restart server
4. Drive through speed traps on SRP → Pictures posted to Discord!

## 📊 Plugin Combinations

### Traffic Server (Your Setup)
```yaml
EnablePlugins:
  - RandomWeatherPlugin
  - PatreonSpeedTrapPlugin  # Speed trap violations to Discord
  - PatreonOvertakePlugin   # Requires Hub for leaderboard
  - PatreonHubPlugin        # Connects to Hub
```

### Racing Server
```yaml
EnablePlugins:
  - PatreonTimingPlugin     # Timing stages
  - PatreonSafetyRatingPlugin  # Safety rating
  - PatreonRaceChallengePlugin  # TXR-style challenges
  - PatreonHubPlugin
```

## 📚 Documentation

- Plugin Docs: https://assettoserver.org/patreon-docs/category/plugins/
- Hub Docs: https://assettoserver.org/patreon-docs/assettoserver-hub/
- Discord Bot: https://assettoserver.org/patreon-docs/assettoserver-hub/discord

## ⚠️ Current Status

- ✅ Patreon license key working (`patreon.key`)
- ✅ PatreonOvertakePlugin loaded
- ❌ No Hub installed → Leaderboards won't work yet
- ✅ Can enable PatreonSpeedTrapPlugin immediately!

## 🎯 Next Steps

1. **Quick Win**: Enable PatreonSpeedTrapPlugin with Discord webhook (5 minutes)
2. **Full Setup**: Download and configure AssettoServer Hub (30-60 minutes)
3. **Advanced**: Enable other plugins once Hub is running

---

Let me know which approach you want to take!
