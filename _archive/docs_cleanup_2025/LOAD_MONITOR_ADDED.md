# 🚨 Load Monitoring Feature Added - Nov 9, 2025

## ✅ What Was Added

### Enhanced `dynamic_traffic.py` with intelligent server load monitoring:

1. **Real-time Server Monitoring**
   - Checks CPU, memory, and system load every 60 seconds
   - Monitors AssettoServer process health
   - No external dependencies (uses built-in Linux tools)

2. **Player Spike Detection**
   - Tracks player count changes over 5-minute windows
   - Alerts when +5 players join quickly
   - Triggers precautionary load checks

3. **Emergency Traffic Reduction**
   - Automatically reduces AI to 50% when server is stressed
   - Uses state machine: normal → warning → critical → recovering
   - Requires 2 consecutive warnings before acting (prevents false positives)

4. **Smart Recovery System**
   - Waits 5 minutes after load normalizes
   - Gradually restores traffic to normal levels
   - Preserves baseline configurations per preset

## 🎯 How It Helps

### Problem Solved
**Before**: During unexpected player spikes or events, server could get overloaded and lag/crash
**Now**: System automatically reduces AI traffic when stressed, preventing crashes

### Example Scenario
```
18:00 - Normal operation: 15 players, 85% AI (51 AI/player)
18:05 - Event starts: 30 players join rapidly
18:06 - System detects spike, monitors closely
18:07 - CPU hits 86%, memory at 3.2GB → CRITICAL
18:08 - AI automatically reduced to 50% (25 AI/player)
18:10 - Load stabilizes at safe levels
18:15 - Recovery delay complete
18:16 - Traffic restored to normal (adjusted for 30 players)
```

## 📊 Configuration

All thresholds are configurable in `dynamic_traffic.py`:

```python
LOAD_CONFIG = {
    'enabled': True,
    
    # CPU Thresholds
    'cpu_warning': 75.0,      # Start monitoring
    'cpu_critical': 85.0,     # Emergency reduction
    'cpu_recovery': 60.0,     # Safe to restore
    
    # Memory Thresholds
    'memory_warning': 2.5,    # GB
    'memory_critical': 3.5,   # GB
    'memory_recovery': 2.0,   # GB
    
    # Player Spike
    'spike_threshold': 5,     # +5 players
    'spike_duration': 300,    # Over 5 minutes
    
    # Emergency Actions
    'emergency_ai_multiplier': 0.50,  # 50% reduction
    'recovery_delay': 300,     # 5 minutes
    'min_checks_before_action': 2,
}
```

## 🚀 Usage

### Check Current Server Load
```bash
python3 dynamic_traffic.py --check-load
```

### View Full Feature Schedule
```bash
python3 dynamic_traffic.py --schedule
```

### Monitor Live Logs
```bash
journalctl --user -u dynamic-traffic.service -f
# or
tail -f logs/dynamic_traffic.log
```

### Service Management
```bash
# Already running! Changes applied on restart
systemctl --user status dynamic-traffic.service
systemctl --user restart dynamic-traffic.service
```

## 📝 Log Examples

### Normal Operation
```
[2025-11-09 09:13:20] ⏰ 09:13 - Active: ☀️ Morning Rush | Players: 12 | Server: ✅ NORMAL
```

### Player Spike Detected
```
[2025-11-09 18:05:23] ⚡ PLAYER SPIKE DETECTED! +10 players in 120s
[2025-11-09 18:05:23] 👥 Current Players: 25
```

### Emergency Reduction
```
[2025-11-09 18:07:06] 📊 Server Status: CRITICAL | CPU: 86.4% | Mem: 2.94GB | Load: 3.58
[2025-11-09 18:07:06] 🚨 EMERGENCY TRAFFIC REDUCTION - CPU CRITICAL (86.4%)
[2025-11-09 18:07:07] ✓ AI REDUCED: 58 → 29 (50%)
```

### Recovery
```
[2025-11-09 18:15:23] ✅ SERVER RECOVERED - Restoring normal traffic
[2025-11-09 18:15:24] ✓ AI RESTORED: 29 → 58
```

## 🔧 Tuning Guide

### If Emergency Reductions Happen Too Often
**Make it less sensitive:**
- Increase `cpu_critical` to 90%
- Increase `memory_critical` to 4.0 GB
- Increase `min_checks_before_action` to 3

### If Server Still Struggles Under Load
**Make it more aggressive:**
- Lower `cpu_warning` to 70%
- Lower `emergency_ai_multiplier` to 0.40 (40% instead of 50%)
- Increase `recovery_delay` to 600 (10 min instead of 5)

### If Recovery is Too Slow
- Decrease `recovery_delay` to 180 (3 minutes)
- Lower `cpu_recovery` to 65%

## 🎯 Integration with Existing Features

Works seamlessly with:
- ✅ **6-hour preset rotation** - Load monitoring respects current preset
- ✅ **Player-based scaling** - Emergency reduction overrides normal scaling
- ✅ **Poll-based adjustments** - Coming soon, will work together
- ✅ **Manual traffic changes** - Won't interfere with admin adjustments

## 📚 Documentation

- **Full Guide**: `SERVER_LOAD_MONITOR.md`
- **AI Context**: `CLAUDE.md` (updated)
- **Code**: `dynamic_traffic.py` (lines 1-250 have new functions)

## ✅ Testing Results

```bash
$ python3 dynamic_traffic.py --check-load
🔍 SERVER LOAD CHECK
Status: NORMAL
CPU Usage: 0.3%
Memory Usage: 0.26 GB
Load Average: 0.28
✅ All metrics healthy
```

Service running successfully:
```bash
$ systemctl --user status dynamic-traffic.service
● dynamic-traffic.service - RedLine Souls - Dynamic Traffic Rotation
     Active: active (running) since Sun 2025-11-09 08:13:20 UTC
```

## 🎉 Benefits

1. **Automatic Protection** - No manual intervention needed
2. **Prevents Crashes** - Reduces load before failure
3. **Handles Events** - Adapts to unexpected player spikes
4. **Smart Recovery** - Doesn't stay reduced unnecessarily
5. **Zero Dependencies** - Uses built-in Linux tools
6. **Fully Logged** - Easy to monitor and debug

---

**Status**: ✅ **DEPLOYED AND ACTIVE**
**Service**: Restarted at 08:13:20 UTC on Nov 9, 2025
**Next Steps**: Monitor logs during peak hours to verify behavior
