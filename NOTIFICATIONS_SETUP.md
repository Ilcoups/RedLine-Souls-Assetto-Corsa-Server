# Player Join/Disconnect Notifications

## ✅ Setup Complete

Two notification systems are now active on your server:

### 1. In-Game Chat Announcements (via RCON)
**What it does:** Posts messages in the in-game chat when players join/disconnect/fail checksums

**Files:**
- `chat_announcer.py` - Python script that monitors server logs
- `start_chat_announcer.sh` - Easy startup script
- RCON enabled on port 27015 in `cfg/extra_cfg.yml`

**Messages shown in-game:**
- ✓ PlayerName joined the server
- ✗ PlayerName left the server  
- ⚠ PlayerName failed checksum verification

**Status:** Running (PID: 149789)

**To manage:**
```bash
# Start
./start_chat_announcer.sh

# Stop
pkill -f chat_announcer.py

# View logs
tail -f chat_announcer.log
```

---

### 2. Discord Webhook Notifications
**What it does:** Posts player connections/disconnections to your Discord channel with Steam IDs

**Configuration:** `cfg/extra_cfg.yml` - DiscordAuditPlugin section

**Webhook URL:** 
```
https://discord.com/api/webhooks/1427443975425364018/8KIkIU-vjxSMEQuMhaiQ3gia-EIFMF48s_98xMTngfthM_A8eW2aDD0M_TjrfOVwJ0ah
```

**Discord messages include:**
- 🔥 Player connected (with name and Steam ID)
- 🏁 Player disconnected (with name and Steam ID)
- Player kick/ban events

**Status:** Active (plugin loaded)

**Note:** The DiscordAuditPlugin in your AssettoServer version may have limited configuration options. The basic webhook functionality works - it will post to Discord when players join/leave. If you need more features (like connection audit toggle), you may need a newer version of AssettoServer.

---

## How It Works

**In-Game Chat (chat_announcer.py):**
1. Monitors `/home/acserver/server/logs/log-YYYYMMDD.txt` every 0.5 seconds
2. Detects join/disconnect/checksum patterns in log lines
3. Sends broadcast messages via RCON `/broadcast` command
4. Players see announcements in their in-game chat

**Discord Webhook (DiscordAuditPlugin):**
1. Plugin hooks into AssettoServer's player connection events
2. Sends HTTP POST to Discord webhook when events occur
3. Messages appear in your Discord channel instantly

---

## Testing

1. **In-game chat:** Join the server and you should see your own join message
2. **Discord:** Check your Discord channel for the webhook message

Both systems work independently - if one fails, the other still works!

---

## Troubleshooting

**Chat announcer not working?**
```bash
# Check if running
ps aux | grep chat_announcer

# Check logs
tail -50 chat_announcer.log

# Restart
pkill -f chat_announcer.py && ./start_chat_announcer.sh
```

**Discord webhook not working?**
```bash
# Check server logs for Discord errors
grep -i discord logs/log-$(date +%Y%m%d).txt

# Check if plugin loaded
grep "Loaded plugin DiscordAuditPlugin" logs/log-$(date +%Y%m%d).txt
```

**RCON not responding?**
- Make sure `RconPort: 27015` in `cfg/extra_cfg.yml`
- Check if port is open: `netstat -tlnp | grep 27015`
- Restart server if needed

---

## Git Commits

- `f3383f7` - Add chat announcer: player join/disconnect/checksum messages in-game! RCON port 27015 enabled, Python script monitors logs and broadcasts to chat
- `351f057` - Add Discord webhook: player join/disconnect notifications with Steam IDs posted to Discord channel
