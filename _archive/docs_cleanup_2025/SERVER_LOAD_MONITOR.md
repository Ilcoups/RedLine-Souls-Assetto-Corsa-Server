# 🚨 Server Load Monitoring & Emergency Scaling

**Added:** November 9, 2025

## 📋 Overview

The dynamic traffic system now includes **intelligent server load monitoring** that automatically reduces AI traffic when the server is struggling, preventing crashes and lag during unexpected player spikes or high-load events.

## ✨ Features

### 1️⃣ **Continuous Load Monitoring**
Checks server health **every 60 seconds**:
- **CPU Usage** - Process and system-wide utilization
- **Memory Usage** - AssettoServer process RAM consumption
- **System Load Average** - Overall server performance indicator

### 2️⃣ **Player Spike Detection**
- Tracks player count changes over 5-minute windows
- Triggers precautionary monitoring when **+5 players join quickly**
- Prepares system for potential load increase

### 3️⃣ **Emergency Traffic Reduction**
When server is overloaded:
- **Automatically reduces AI to 50%** of current levels
- Stores baseline configuration for recovery
- Prevents server crashes during stress

### 4️⃣ **Smart Recovery**
After load normalizes:
- Waits **5 minutes** to ensure stability
- Gradually restores normal traffic levels
- Returns to preset-based and player-based scaling

## 🎚️ Thresholds

### CPU
- **Warning:** 75% → Start monitoring closely
- **Critical:** 85% → Emergency reduction
- **Recovery:** < 60% → Safe to restore

### Memory (AssettoServer process)
- **Warning:** 2.5 GB → Monitor
- **Critical:** 3.5 GB → Reduce traffic
- **Recovery:** < 2.0 GB → Restore

### System Load (1-min average on 4-core system)
- **Warning:** 3.0 (75% utilization)
- **Critical:** 3.5 (87.5% utilization)
- **Recovery:** < 2.5 (62.5% utilization)

## 🔧 Configuration

Edit `/home/acserver/server/dynamic_traffic.py`:

```python
LOAD_CONFIG = {
    'enabled': True,  # Toggle load monitoring
    'cpu_warning': 75.0,
    'cpu_critical': 85.0,
    'memory_warning': 2.5,
    'memory_critical': 3.5,
    'emergency_ai_multiplier': 0.50,  # Reduce to 50%
    'recovery_delay': 300,  # 5 minutes
    'min_checks_before_action': 2,  # Consecutive warnings
}
```

## 📊 State Machine

```
NORMAL → Player spike or load warning
  ↓
WARNING → Load continues high
  ↓
CRITICAL → Emergency AI reduction (50%)
  ↓
RECOVERING → Load normalizes, wait 5 min
  ↓
NORMAL → Traffic restored
```

## 🚀 Usage

### Check Current Server Load
```bash
python3 dynamic_traffic.py --check-load
```

Output:
```
🔍 SERVER LOAD CHECK
Status: NORMAL
CPU Usage: 45.2%
Memory Usage: 1.87 GB
Load Average: 1.92

✅ All metrics healthy
```

### View Full Feature Set
```bash
python3 dynamic_traffic.py --schedule
```

### Monitor Logs
```bash
tail -f logs/dynamic_traffic.log
```

## 📈 How It Works Together

### Normal Operation
1. **Preset Rotation** - Changes traffic every 6 hours
2. **Player Scaling** - Adjusts AI based on player count (0-10 = 100%, 26+ = 65%)
3. **Load Monitoring** - Checks health every minute

### During Event with Spike
```
18:00 - 15 players online, AI at 85% (normal)
18:05 - 25 players join! (player spike detected)
18:06 - System detects high CPU (78%)
18:07 - CPU at 86% (critical), AI reduced to 50%
18:10 - Load normalizes to 65%
18:15 - Recovery delay complete, AI restored to 70% (25 players)
```

### Example Log Output
```
[2025-11-09 18:05:23] ⚡ PLAYER SPIKE DETECTED! +10 players in 120s
[2025-11-09 18:06:14] 📊 Server Status: WARNING | CPU: 78.3% | Mem: 2.61GB | Load: 3.12
[2025-11-09 18:07:05] 📊 Server Status: CRITICAL | CPU: 86.4% | Mem: 2.94GB | Load: 3.58
[2025-11-09 18:07:06] 🚨 EMERGENCY TRAFFIC REDUCTION - CPU CRITICAL (86.4%)
[2025-11-09 18:07:07] ✓ AI REDUCED: 58 → 29 (50%)
[2025-11-09 18:10:22] 📊 Server Status: NORMAL | CPU: 61.2% | Mem: 2.12GB | Load: 2.38
[2025-11-09 18:15:23] ✅ SERVER RECOVERED - Restoring normal traffic
[2025-11-09 18:15:24] ✓ AI RESTORED: 29 → 58
```

## ⚙️ Systemd Service

The service is already running, restart to apply changes:

```bash
systemctl --user restart dynamic-traffic.service
journalctl --user -u dynamic-traffic.service -f
```

## 🎯 Benefits

✅ **Prevents Crashes** - Automatically reduces load before failure
✅ **Handles Spikes** - Adapts to unexpected player influx
✅ **Smart Recovery** - Doesn't reduce unnecessarily or restore too quickly
✅ **No Manual Intervention** - Fully automatic protection
✅ **Preserves Experience** - Only reduces when truly needed

## 🔍 Monitoring

### Check Service Status
```bash
systemctl --user status dynamic-traffic.service
```

### View Recent Logs
```bash
tail -n 50 logs/dynamic_traffic.log
```

### Check Current State
```bash
# Look for state indicators in logs
grep "Server Status" logs/dynamic_traffic.log | tail -5
```

## 🛠️ Tuning

If you experience too many/few emergency reductions:

1. **More sensitive** (reduce earlier):
   - Lower `cpu_warning` to 70%
   - Lower `memory_warning` to 2.0 GB

2. **Less sensitive** (only on severe load):
   - Raise `cpu_critical` to 90%
   - Increase `min_checks_before_action` to 3

3. **Faster recovery**:
   - Reduce `recovery_delay` to 180 (3 min)

4. **Gentler emergency reduction**:
   - Change `emergency_ai_multiplier` to 0.65 (65% instead of 50%)

## 🐛 Troubleshooting

**Load monitoring not working:**
```bash
# Check if script can find AssettoServer process
pgrep -f AssettoServer

# Test load check manually
python3 dynamic_traffic.py --check-load
```

**Emergency reductions happening too often:**
- Check actual server resources: `htop` or `top`
- Review thresholds in config
- Consider upgrading server hardware

**Traffic not restoring after recovery:**
- Check logs for errors: `tail -f logs/dynamic_traffic.log`
- Verify config file permissions
- Restart service

## 📝 Notes

- **Only reduces during genuine emergencies** - Uses consecutive check logic
- **Preserves player-based scaling** - Works alongside existing features
- **Graceful degradation** - Better reduced traffic than server crash
- **Automatic recovery** - No admin intervention needed

---

**Made with ❤️ for RedLine Souls community**
