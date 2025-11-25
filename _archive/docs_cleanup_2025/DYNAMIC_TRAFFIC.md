# Dynamic Traffic Rotation System

**4 Daily Traffic Cycles - Every 6 Hours | NO Server Restart!**

## 🎯 Quick Commands

```bash
# Check status
systemctl --user status dynamic-traffic.service

# View logs (live)
tail -f /home/acserver/server/logs/dynamic_traffic.log

# Show schedule
python3 /home/acserver/server/dynamic_traffic.py --schedule

# Apply current preset now
python3 /home/acserver/server/dynamic_traffic.py --apply-now

# Restart service
systemctl --user restart dynamic-traffic.service
```

## 📅 Daily Rotation Schedule (Amsterdam Time)

### 00:00 - 06:00 | � Night Cruise
**Chill late-night vibes**
- Density: 1.20 (light) | Speed: 90 km/h | AI/player: 35
- Spacing: 40-97m | Highway: 110 km/h
- Perfect for: Relaxed night drives, testing, photography

### 06:00 - 12:00 | ☀️ Morning Rush
**Dense commuter traffic, push hard!**
- Density: 0.80 (DENSE) | Speed: 103 km/h | AI/player: 58
- Spacing: 31-76m | Highway: 123 km/h
- Perfect for: Overtaking challenges, aggressive driving

### 12:00 - 18:00 | �️ Afternoon Flow
**Balanced experience**
- Density: 0.95 (moderate) | Speed: 95 km/h | AI/player: 48
- Spacing: 35-85m | Highway: 115 km/h
- Perfect for: Standard sessions, learning, consistent practice

### 18:00 - 00:00 | 🌆 Evening Attack
**Fast & aggressive highway battles**
- Density: 0.85 (dense) | Speed: 107 km/h | AI/player: 55
- Spacing: 29-72m | Highway: 127 km/h
- Perfect for: Time attacks, high-speed runs, intense battles

## ⚙️ How It Works

- **Checks every 30 minutes** for time-based preset changes
- **Changes automatically** at 00:00, 06:00, 12:00, 18:00
- **Hot-reload config** - players never disconnect!
- **Smooth transition** - existing AI continues, new spawns use new settings
- **Auto-backup** - every change backs up previous config

## 📂 Files

- Script: `/home/acserver/server/dynamic_traffic.py` (209 lines)
- Service: `~/.config/systemd/user/dynamic-traffic.service`
- Config: `/home/acserver/server/cfg/extra_cfg.yml`
- Logs: `/home/acserver/server/logs/dynamic_traffic.log`
- Backups: `/home/acserver/server/cfg/traffic_presets/backup_*.yml`

## 🔧 Customization

Edit preset modifiers in `dynamic_traffic.py`:

```python
# Example: Make morning rush even MORE aggressive
TRAFFIC_PRESETS = {
    "morning": create_preset("Morning Rush", "☀️", [6,7,8,9,10,11], 
                             0.70,  # density (lower = more cars)
                             15,    # speed_mod (+15 kph)
                             65,    # ai_count
                             0.85,  # spacing_mod (closer)
                             True), # aggressive=True
    # ... other presets
}
```

After changes: `systemctl --user restart dynamic-traffic.service`

## 🐛 Troubleshooting

```bash
# Service issues
systemctl --user status dynamic-traffic.service
journalctl --user -u dynamic-traffic.service -n 50

# Config not changing
tail -50 /home/acserver/server/logs/dynamic_traffic.log

# Force specific time period (testing)
# Edit dynamic_traffic.py, modify get_current_preset() to return fixed value
```

---

**Code size**: 209 lines (vs 700+ original) | **Token efficient for AI assistants** ✅

