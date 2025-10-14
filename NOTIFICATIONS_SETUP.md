# Player Join/Disconnect Notifications

## ✅ Discord Webhook - WORKING

Discord notifications are now active on your server:

### Discord Webhook Notifications
**What it does:** Posts player connections/disconnections to your Discord channel with Steam IDs and car info

**Files:**
- `discord_announcer.py` - Python script that monitors server logs and posts to Discord
- `start_discord_announcer.sh` - Easy startup script

**Webhook URL:** 
```
https://discord.com/api/webhooks/1427443975425364018/8KIkIU-vjxSMEQuMhaiQ3gia-EIFMF48s_98xMTngfthM_A8eW2aDD0M_TjrfOVwJ0ah
```

**Discord messages include:**
- � **PlayerName** joined (Steam: 76561199185532445, Car: ferrari_f40_s3)
- 🔴 **PlayerName** left the server
- ⚠️ **PlayerName** failed checksum verification

**Status:** Running

**To manage:**
```bash
# Start
./start_discord_announcer.sh

# Stop
pkill -f discord_announcer.py

# View logs
tail -f discord_announcer.log

# Check if running
pgrep -a discord_announcer
```

---

## How It Works

**Discord Announcer (discord_announcer.py):**
1. Monitors `/home/acserver/server/logs/log-YYYYMMDD.txt` every 0.5 seconds
2. Detects join/disconnect/checksum patterns in log lines using regex
3. Extracts player name, Steam ID, and car information
4. Sends formatted embed messages to Discord webhook
5. Messages appear in your Discord channel instantly with color-coded events

**Log Pattern Matching:**
- Join: `il (76561199185532445, 26 (ferrari_f40_s3-02_black/ADAn)) has connected`
- Disconnect: `il has disconnected`
- Checksum fail: Any line containing "checksum" and "fail"/"error"

---

## Testing

**Join your server and check Discord!** You should see:
- Startup message when announcer starts
- Green circle when you join (with Steam ID and car)
- Red circle when you disconnect

The script runs in the background and automatically handles log rotation (new day = new log file).

---

## Troubleshooting

**Discord announcer not working?**
```bash
# Check if running
ps aux | grep discord_announcer

# Check logs for errors
tail -50 discord_announcer.log

# Restart
pkill -f discord_announcer.py && ./start_discord_announcer.sh

# Test webhook manually
curl -X POST "YOUR_WEBHOOK_URL" -H "Content-Type: application/json" \
  -d '{"content": "Test message"}'
```

**No messages in Discord?**
1. Check if announcer is running: `pgrep -f discord_announcer`
2. Check log file exists: `ls -lh logs/log-$(date +%Y%m%d).txt`
3. Verify webhook URL is correct in `discord_announcer.py`
4. Test webhook with curl (see above)

**Messages delayed?**
- Check interval is 0.5 seconds - should be nearly instant
- Server logs may be buffered - check `discord_announcer.log` for recent activity

---

## Git Commits

- `b6fa87b` - FIX: Discord announcer working! Posts player join/leave with Steam IDs. Removed broken RCON chat announcer. Simple Python script monitors logs and uses Discord webhook directly.

## Note on In-Game Chat Announcements

RCON-based in-game chat announcements were attempted but AssettoServer's RCON implementation is complex and unreliable for this use case. Discord notifications work perfectly and provide more detailed information (Steam IDs, car info, timestamps).

If you absolutely need in-game chat announcements, consider:
1. Using a proper RCON library like `mcrcon`
2. Implementing via AssettoServer plugin (requires C# development)
3. Using CSP Lua scripts (client-side only)
