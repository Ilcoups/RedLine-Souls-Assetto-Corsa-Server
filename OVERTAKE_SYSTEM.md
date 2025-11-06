# RedLine Souls - Custom Overtake Tracker

## 🎯 Overview

**No Patreon required!** Custom overtake tracking using CSP's built-in Lua capabilities that ALL players with CSP already have.

## 🏗️ Architecture

### Client-side (Lua)
- **File**: `csp_scripts/overtake_tracker.lua`
- **Runs on**: Each player's game (CSP Lua runtime)
- **Does**: Detects when you pass another player, sends UDP packet to server
- **Detection**: Uses car position + velocity vectors (like Patreon plugin)

### Server-side (Python)
- **File**: `overtake_tracker.py`
- **Does**: Receives UDP packets, tracks stats, posts hourly leaderboard to Discord
- **Storage**: `overtake_stats.json` (persistent across restarts)

## 📋 Installation

### For Server Admin (You)

1. **Server is ready** - Files already created:
   - `/home/acserver/server/overtake_tracker.py` - Server tracker
   - `/home/acserver/server/csp_scripts/overtake_tracker.lua` - Client script

2. **Start tracker**:
   ```bash
   cd /home/acserver/server
   nohup python3 overtake_tracker.py > overtake_tracker.log 2>&1 &
   ```

3. **Verify running**:
   ```bash
   ps aux | grep overtake_tracker
   tail -f overtake_tracker.log
   ```

4. **Add to start_server.sh** (optional):
   ```bash
   # Add after player_stats.py
   nohup python3 overtake_tracker.py > overtake_tracker.log 2>&1 &
   echo "✓ Overtake Tracker started"
   ```

### For Players

**Option 1: Manual Install** (Recommended for testing)
1. Download: `csp_scripts/overtake_tracker.lua`
2. Copy to: `Documents/Assetto Corsa/cfg/lua/online/overtake_tracker.lua`
3. Restart AC
4. Join server - overtakes auto-tracked!

**Option 2: Share on Discord** (For all players)
Post the file + instructions in your Discord so players can opt-in.

**⚠️ Important**: Cannot be server-forced. Each player installs manually.

## 🎮 How It Works

### Detection Algorithm

```
1. Every frame, check all nearby cars (<20m)
2. Calculate if they're ahead/behind using velocity vector
3. If car transitions from "ahead" to "behind":
   - Speed > 80 km/h ✅
   - Cooldown passed (3s) ✅
   - Distance > 2m behind ✅
   → OVERTAKE! Send to server
```

### Server Tracking

```
UDP Packet from client:
[steam_id_length][steam_id][name_length][name][speed_kph][count]

Server stores:
{
  "76561198XXXXXX": {
    "name": "PlayerName",
    "total_overtakes": 1337,
    "best_speed": 245.6,
    "last_seen": "2025-11-06T21:00:00Z"
  }
}
```

### Discord Leaderboard (Hourly)

```
🏎️ RedLine Souls - Overtake Leaderboard

🥇 **Player1** - 1,337 overtakes (best: 256 km/h)
🥈 **Player2** - 892 overtakes (best: 241 km/h)
🥉 **Player3** - 654 overtakes (best: 238 km/h)
4. **Player4** - 521 overtakes (best: 229 km/h)
...
```

## ⚙️ Configuration

### Server Settings (`overtake_tracker.py`)

```python
UDP_LISTEN_PORT = 12002  # Server UDP port
LEADERBOARD_INTERVAL = 3600  # Post every hour (seconds)
MIN_SPEED_KPH = 80  # Minimum speed to count
```

### Client Settings (`overtake_tracker.lua`)

```lua
local SERVER_UDP_IP = "188.245.183.146"  -- Your server IP
local SERVER_UDP_PORT = 12002
local MIN_SPEED_KPH = 80  -- Must match server
local OVERTAKE_DISTANCE = 7  -- Meters ahead
local COOLDOWN_TIME = 3.0  -- Seconds between same-car overtakes
```

## 🔧 Advantages Over Patreon Plugin

| Feature | Custom System | PatreonOvertakePlugin |
|---------|---------------|----------------------|
| **Cost** | Free | $5/month Patreon |
| **Player Download** | Manual Lua install | Automatic via server |
| **Detection** | Client-side (accurate) | Server-side (network lag) |
| **Customization** | Full source access | Closed source |
| **Storage** | JSON (simple) | SQLite (complex) |
| **Dependencies** | Python 3 (already have) | PatreonHubPlugin required |

## 🐛 Debugging

### Client-side (Player)

1. Enable AC console log
2. Check: `Documents/Assetto Corsa/logs/log.txt`
3. Look for: `"RedLine Souls Overtake Tracker initialized"`
4. After overtake: `"Overtook PlayerName @ 123.4 km/h"`

### Server-side (Admin)

```bash
# Check if running
ps aux | grep overtake_tracker

# View live logs
tail -f /home/acserver/server/overtake_tracker.log

# Check stats file
cat /home/acserver/server/overtake_stats.json | jq

# Test UDP port
netstat -ulnp | grep 12002
```

### Common Issues

**No overtakes recorded**:
- Check player installed Lua script correctly
- Verify server UDP port open: `ss -ulnp | grep 12002`
- Check server IP in Lua script matches actual server

**Leaderboard not posting**:
- Verify `DISCORD_STATS_WEBHOOK` in `.env`
- Check overtake_tracker.log for Discord errors
- Ensure at least 1 overtake recorded

## 🚀 Future Improvements

1. **Multiplier system** (like Patreon plugin):
   - Consecutive overtakes without being overtaken = bonus points
   - Reset on crash or being overtaken

2. **Real-time notifications**:
   - Send chat message on milestone (100, 500, 1000 overtakes)
   - Broadcast top overtaker every 10 minutes

3. **AI traffic filtering**:
   - Currently tracks real players only
   - Could add AI overtakes with lower weight

4. **Web dashboard**:
   - Add to `wwwroot/index.html` status page
   - Live top 5 overtakers

## 📝 Notes

- **Client-side detection** = More accurate than server-side (no network lag)
- **UDP communication** = Lightweight, no TCP overhead
- **JSON storage** = Simple, human-readable, easy backups
- **Hourly leaderboard** = Balances engagement vs spam

---

**Next Steps**:
1. Start `overtake_tracker.py` on server
2. Test with 1-2 players installing Lua script
3. Verify logs show overtakes
4. Wait 1 hour for first leaderboard post
5. Share Lua script on Discord for all players
