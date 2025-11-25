# 🚨 Load Monitor - Quick Reference

## Quick Status Checks

```bash
# Check current server load
python3 dynamic_traffic.py --check-load

# View live logs
tail -f logs/dynamic_traffic.log

# Check service status
systemctl --user status dynamic-traffic.service

# View recent service logs
journalctl --user -u dynamic-traffic.service -n 50
```

## What the Emojis Mean

- ✅ NORMAL - All good, no issues
- ⚠️ WARNING - Load elevated, monitoring closely
- 🚨 CRITICAL - Emergency reduction active
- ⚡ PLAYER SPIKE - Rapid player increase detected
- 👥 Player count changed
- 📊 Server health metrics
- 🔧 Configuration applied

## State Meanings

| State | What It Means | Action |
|-------|---------------|---------|
| NORMAL | Server healthy | Normal traffic operation |
| WARNING | Load elevated but manageable | Monitoring more closely |
| CRITICAL | Server overloaded | AI reduced to 50% |
| RECOVERING | Load normalized, waiting | Will restore in 5 min |

## Thresholds at a Glance

| Metric | Warning | Critical | Recovery |
|--------|---------|----------|----------|
| CPU | 75% | 85% | <60% |
| Memory | 2.5 GB | 3.5 GB | <2.0 GB |
| Load Avg | 3.0 | 3.5 | <2.5 |

## Common Scenarios

### Scenario: Emergency reduction activated
**Look for in logs:**
```
🚨 EMERGENCY TRAFFIC REDUCTION - CPU CRITICAL (86.4%)
✓ AI REDUCED: 58 → 29 (50%)
```
**What to do:** Nothing! System will auto-recover when load drops

### Scenario: Player spike but no reduction
**Look for in logs:**
```
⚡ PLAYER SPIKE DETECTED! +10 players in 120s
📊 Server Status: NORMAL | CPU: 61.2% | ...
```
**What to do:** Good! Server handled it without emergency measures

### Scenario: Frequent emergency reductions
**Look for in logs:**
```
🚨 EMERGENCY TRAFFIC REDUCTION (appears often)
```
**What to do:** Server may need more resources, or tune thresholds less sensitive

## Quick Tuning

**Edit `/home/acserver/server/dynamic_traffic.py`**

### Make Less Sensitive (fewer emergencies)
```python
'cpu_critical': 90.0,          # Was 85.0
'memory_critical': 4.0,        # Was 3.5
'min_checks_before_action': 3, # Was 2
```

### Make More Aggressive (more protection)
```python
'cpu_warning': 70.0,              # Was 75.0
'emergency_ai_multiplier': 0.40,  # Was 0.50 (40% instead of 50%)
```

**After editing, restart:**
```bash
systemctl --user restart dynamic-traffic.service
```

## Disable Load Monitoring

If you want to disable this feature:

```python
# In dynamic_traffic.py
LOAD_CONFIG = {
    'enabled': False,  # Change to False
    ...
}
```

Then restart:
```bash
systemctl --user restart dynamic-traffic.service
```

Player-based scaling will still work, just no emergency load protection.

## Key Files

- `/home/acserver/server/dynamic_traffic.py` - Main script
- `/home/acserver/server/logs/dynamic_traffic.log` - Log file
- `/home/acserver/server/SERVER_LOAD_MONITOR.md` - Full docs
- `~/.config/systemd/user/dynamic-traffic.service` - Service file

## Normal Log Pattern

Every 5 minutes you should see:
```
[Time] 👥 Current Players: X
```

Every 30 minutes:
```
[Time] ⏰ HH:MM - Active: [Preset] | Players: X | Server: ✅ NORMAL
```

Every 6 hours:
```
[Time] ⏰ HH:MM - Switching to [New Preset]
```

If you see `🚨`, `⚠️`, or `⚡` frequently, check server resources!
