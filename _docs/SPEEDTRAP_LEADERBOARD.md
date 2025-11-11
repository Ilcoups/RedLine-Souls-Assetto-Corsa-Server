# Speed Trap Discord Leaderboard Setup

## Overview
Tracks speed camera violations and displays the most reckless drivers on Discord.

## System Components

**1. Speed Trap Proxy** (`speed_trap_proxy.py`)
- Receives violations from PatreonSpeedTrapPlugin
- Forwards to Discord webhook
- NOW ALSO: Saves violation data to `_utils/speed_trap_stats.json`

**2. Statistics File** (`_utils/speed_trap_stats.json`)
- Stores last 1000 violations
- Tracks: driver name, speed, limit, camera ID, timestamp

**3. Discord Leaderboard Updater** (`_utils/update_discord_speedtrap.py`)
- Reads violation stats
- Aggregates by driver
- Updates Discord message every 60s (via systemd timer)

## Installation Steps

### 1. Create Discord Message
```bash
# Use Discord bot to create initial leaderboard message
# Copy the message ID for next step
```

### 2. Configure Message ID
Edit `_utils/update_discord_speedtrap.py`:
```python
message_id = "YOUR_MESSAGE_ID_HERE"  # Line ~143
```

### 3. Create Systemd Timer
Create `~/.config/systemd/user/speedtrap-leaderboard.service`:
```ini
[Unit]
Description=Speed Trap Leaderboard Updater
After=network.target

[Service]
Type=oneshot
ExecStart=/home/acserver/server/_utils/update_discord_speedtrap.py
WorkingDirectory=/home/acserver/server
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

Create `~/.config/systemd/user/speedtrap-leaderboard.timer`:
```ini
[Unit]
Description=Speed Trap Leaderboard Timer - Every 60 seconds
After=network.target

[Timer]
OnBootSec=2min
OnUnitActiveSec=1min
Persistent=true

[Install]
WantedBy=timers.target
```

### 4. Enable Timer
```bash
systemctl --user daemon-reload
systemctl --user enable speedtrap-leaderboard.timer
systemctl --user start speedtrap-leaderboard.timer
systemctl --user status speedtrap-leaderboard.timer
```

## Leaderboard Features

**Rankings Based On:**
- Total violations (primary)
- Total km/h over limit (secondary)
- Maximum speed recorded (tertiary)

**Top 3 Display:**
- Medal emojis (🥇🥈🥉)
- Violation count with percentage
- Max speed and average over-limit
- Mock "fines" ($50 per violation)

**Rest of Pack:**
- Clean numbered list
- Violations and max speed

**Statistics:**
- Total violations across all drivers
- Number of reckless drivers
- Real-time updates every 60 seconds

## Data Retention

**Violations:** Last 1000 entries kept in `_utils/speed_trap_stats.json`

**Auto-cleanup:** Old violations automatically removed when limit reached

## Troubleshooting

### No Violations Showing
```bash
# Check if speed trap proxy is saving data
cat _utils/speed_trap_stats.json

# Check proxy logs
journalctl --user -u speed-trap-proxy.service -n 50

# Trigger a violation in-game to test
```

### Leaderboard Not Updating
```bash
# Check timer status
systemctl --user status speedtrap-leaderboard.timer

# Check service logs
journalctl --user -u speedtrap-leaderboard.service -n 20

# Run manually to see errors
./_utils/update_discord_speedtrap.py
```

### Proxy Not Saving Stats
```bash
# Restart proxy
systemctl --user restart speed-trap-proxy.service

# Check logs for errors
tail -f speed_trap_buffer/webhook_proxy.log
```

## Example Leaderboard Output

```
# 🚨 SPEED TRAP LEADERBOARD

42 VIOLATIONS ┃ 12 RECKLESS DRIVERS
Last updated: Nov 11, 2025 • 15:00 UTC

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 🥇 #1 · PlayerName
> 🚨 **15** violations (100%)
> ⚡ Max: **245 km/h** · Avg over: **+45 km/h**
> 💸 Total fines: **$750**

## 🥈 #2 · AnotherDriver
> 🚨 **12** violations (80%)
> ⚡ Max: **230 km/h** · Avg over: **+38 km/h**
> 💸 Total fines: **$600**
```

## Integration with Existing Systems

**Independent:** Runs separately from overtake leaderboard

**Same Channel:** Can be posted in same Discord channel

**Same Bot:** Uses same Discord bot token from Hub config

**Same Update Pattern:** 60-second update cycle like overtake leaderboard

## Notes

- Violations are tracked from the moment the proxy was updated
- Historical data before today will not be available
- Mock fines ($50/violation) are for fun, not real
- Leaderboard highlights most reckless, not best, drivers
- Clean slate when `speed_trap_stats.json` is deleted

---

**Status**: Code ready, needs Discord message creation + timer setup
**Updates**: Every 60 seconds
**Retention**: Last 1000 violations
