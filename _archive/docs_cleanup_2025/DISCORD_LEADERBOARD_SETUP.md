# Discord Leaderboard Setup Guide

## ✅ Current Status

**Hub is running with Discord bot connected!**

- Hub PID: Check with `pgrep -f AssettoServer.Hub`
- Discord Bot: Connected and ready
- Patreon Plugins: Enabled (PatreonHubPlugin, PatreonOvertakePlugin)
- Leaderboard Name: **RedLine Souls** (configured in `cfg/extra_cfg.yml`)

## 📊 How to Create Discord Leaderboard

**IMPORTANT**: The `/overtake-leaderboard` command posts **directly to the channel** where you run it. You do NOT need webhooks or templates for basic leaderboards!

### Steps:

1. Go to your Discord server
2. Navigate to the `#leaderboard` channel (or any channel where you want the leaderboard)
3. Type: `/overtake-leaderboard`
4. The bot will ask for a **leaderboard name**
5. Type: `RedLine Souls` (must match the `LeaderboardName` in your `cfg/extra_cfg.yml`)
6. The bot will create a leaderboard embed in that channel
7. The leaderboard will auto-update as players get overtakes!

### What the Command Does:

- Posts an embed message directly to the channel
- Updates automatically when new overtake data arrives
- No webhook configuration needed for basic usage
- Bot handles everything through Discord API

## 🔧 Advanced: Custom Templates (Optional)

If you want **multiple leaderboard styles** or **specific formatting**, you can define custom templates in `hub/configuration.yml`:

```yaml
DiscordOvertakeLeaderboardTemplates:
  my-custom-template:
    # Template configuration here
    # Documentation: https://assettoserver.org/patreon-docs/assettoserver-hub/discord/
```

**But this is NOT required** for basic leaderboards!

## ❌ Common Mistakes

1. **Don't use webhooks** - The bot posts directly, webhooks are for advanced use cases
2. **Match the leaderboard name** - Must be exactly `RedLine Souls` (from `cfg/extra_cfg.yml`)
3. **Bot must be in the channel** - Make sure your Discord bot has permissions to post in `#leaderboard`
4. **Hub must be running** - Check with `ps aux | grep AssettoServer.Hub`

## 🐛 Troubleshooting

### "Template not found" error
- Just type `RedLine Souls` as the leaderboard name
- If it asks for a template, leave the templates section empty in Hub config (it's optional)

### "Bot not responding"
```bash
# Check Hub logs
tail -f /home/acserver/server/hub/hub.log | grep Discord

# Should see:
# [INF] [Discord:Gateway] Ready
```

### "Leaderboard not updating"
```bash
# Check if PatreonOvertakePlugin is enabled
grep "PatreonOvertakePlugin" cfg/extra_cfg.yml

# Check game server logs
tail -f logs/log-$(date +%Y%m%d).txt | grep Overtake
```

## 📁 Configuration Files

### Hub Config (`hub/configuration.yml`)
```yaml
DiscordBotToken: <your-bot-token>
DiscordOvertakeLeaderboardTemplates: {}  # Empty = use default behavior
```

### Game Server Config (`cfg/extra_cfg.yml`)
```yaml
EnablePlugins:
- RandomWeatherPlugin
- PatreonHubPlugin        # Required for Hub connection
- PatreonOvertakePlugin   # Required for overtake tracking

---
!PatreonHubConfiguration
Address: http://localhost:5085
Key: <your-hub-key>

---
!PatreonOvertakeConfiguration
LeaderboardName: RedLine Souls  # MUST match Discord command input
MinimumSpeedKph: 80
OvertakeDistanceMeters: 7
CloseOvertakeDistanceMeters: 4
EnableUIByDefault: true
```

## 🚀 Quick Test

1. Join your Assetto Corsa server
2. Drive next to AI traffic and overtake them
3. Check if overtake messages appear in-game
4. Go to Discord and run `/overtake-leaderboard`
5. Enter `RedLine Souls` when asked
6. Leaderboard should appear!

## 📖 Official Documentation

- Hub Discord Bot: https://assettoserver.org/patreon-docs/assettoserver-hub/discord/
- User Groups: https://assettoserver.org/patreon-docs/assettoserver-hub/user-groups

## ⚙️ Restart Commands

```bash
# Restart everything (Hub + Game Server)
./restart_all.sh

# Restart only Hub
./stop_hub.sh && sleep 2 && ./start_hub.sh

# Check if Hub is connected to game server
tail -20 hub/hub.log | grep "server connected"
```

---

**Last Updated**: 2025-11-07
**Hub Version**: 0.0.8
**Patreon Plugins Version**: 0.0.39
