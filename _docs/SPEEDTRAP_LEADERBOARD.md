# Speed Trap Discord Daily Summary

## Overview
Tracks speed camera violations and posts a daily summary to #daily-statistic channel.

## System Components

**1. Speed Trap Proxy** (`speed_trap_proxy.py`)
- Receives violations from PatreonSpeedTrapPlugin
- Forwards to Discord webhook
- Saves violation data to `_utils/speed_trap_stats.json`

**2. Statistics File** (`_utils/speed_trap_stats.json`)
- Stores last 1000 violations
- Tracks: driver name, speed, limit, camera ID, timestamp

**3. Daily Summary Script** (`_utils/speed_trap_daily_summary.py`)
- Runs daily at 23:59 UTC (via unified-stats.timer)
- Analyzes last 24 hours of violations
- Posts new message to #daily-statistic channel
- Integrated with existing daily stats posting

## How It Works

1. **Throughout the day**: Speed trap violations → Saved to JSON
2. **Daily at 23:59 UTC**: Daily stats script runs
3. **Posts to Discord**: New message with yesterday's violations

## Daily Summary Features

**Top 10 Leaderboard:**
- 🥇🥈🥉 Top 3 medals
- Violation count and max speed
- Ranked by: violations > total over-limit > max speed

**Worst Violation:**
- Highest speed recorded
- Driver name and camera location
- How much over the limit

**Statistics:**
- Total violations
- Number of reckless drivers  
- Active cameras
- Total km/h over limits
- Mock fines issued ($50 each)

## Installation

### Already Done ✅
The system is integrated into existing daily stats:
- `tools/generate_daily_stats.sh` calls speed trap summary
- Runs via `unified-stats.timer` at 23:59 UTC
- Uses same `DISCORD_STATS_WEBHOOK` from `.env`

### Manual Test
```bash
./_utils/speed_trap_daily_summary.py
```

## Example Output

```
🚨 Speed Trap Daily Summary - November 11, 2025

**🏆 TOP 10 MOST RECKLESS DRIVERS**

🥇 PlayerName · 8 violations · Max: 245 km/h
🥈 AnotherDriver · 6 violations · Max: 230 km/h
🥉 RecklessOne · 4 violations · Max: 218 km/h
**4.** Driver4 · 3 violations · Max: 205 km/h
**5.** Driver5 · 2 violations · Max: 198 km/h

**⚠️ WORST VIOLATION OF THE DAY**
**PlayerName** caught at **245 km/h** (+65 km/h over limit)
📸 Camera: #042-003

**📊 DAILY STATISTICS**
• Total Violations: **42**
• Reckless Drivers: **15**
• Active Cameras: **8**
• Total km/h Over Limit: **1,250**
• Mock Fines Issued: **$2,100**

*Keep it under the limit! 🚗💨*
```

## Data Source

**Violations tracked from**: Speed trap proxy start time
**Historical data**: None (starts fresh)
**Retention**: Last 1000 violations in JSON
**Daily summary**: Last 24 hours only

## Integration with Daily Stats

The speed trap summary posts **after** the server health stats in the same timer run:

1. 23:59 UTC - `generate_daily_stats.sh` runs
2. Posts server health (connections, playtime, etc.)
3. Posts speed trap summary (violations, reckless drivers)
4. Both go to `#daily-statistic` channel

## Troubleshooting

### No Summary Posted
```bash
# Check if timer ran
journalctl --user -u unified-stats.service -n 20

# Check if webhook is configured
grep DISCORD_STATS_WEBHOOK .env

# Run manually
./_utils/speed_trap_daily_summary.py
```

### No Violations Showing
```bash
# Check if violations are being saved
cat _utils/speed_trap_stats.json

# Check proxy status
systemctl --user status speed-trap-proxy.service

# Trigger a violation in-game to test
```

### Wrong Time/Timezone
The summary uses last 24 hours from current time, so timezone doesn't affect which violations are included.

## Comparison with Overtake Leaderboard

| Feature | Overtake Leaderboard | Speed Trap Summary |
|---------|---------------------|-------------------|
| Update frequency | Every 60 seconds | Daily at 23:59 UTC |
| Post type | Edit same message | New message daily |
| Channel | Dedicated leaderboard | #daily-statistic |
| Time period | All-time | Last 24 hours |
| Purpose | Track best overtakers | Track reckless drivers |

## Notes

- **New message daily** - Doesn't update existing message
- **Last 24 hours** - Not reset at midnight, rolling window
- **Mock fines** - For fun, not real penalties
- **Integrated** - Part of existing daily stats workflow
- **No separate timer** - Uses unified-stats.timer

---

**Status**: ✅ Active and integrated
**Runs**: Daily at 23:59 UTC
**Channel**: #daily-statistic (via DISCORD_STATS_WEBHOOK)

