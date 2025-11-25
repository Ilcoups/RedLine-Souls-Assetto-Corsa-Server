# Auto-Scaling & Smart Poll System - User Guide

## 🚀 Overview

RedLine Souls now features **two intelligent auto-scaling systems** that automatically optimize AI traffic based on server load and player feedback!

---

## 📊 System 1: Player Count Auto-Scaling

### What It Does
Automatically reduces AI traffic when the server gets crowded to prevent lag and maintain smooth gameplay for everyone.

### How It Works
The system checks player count every **5 minutes** and adjusts AI density on-the-fly without disconnecting anyone!

### Scaling Thresholds

| Players | AI Amount | Reduction |
|---------|-----------|-----------|
| 0-10    | 100% AI   | None      |
| 11-15   | 85% AI    | 15% off   |
| 16-20   | 75% AI    | 25% off   |
| 21-25   | **70% AI**| **30% off**|
| 26+     | 65% AI    | 35% off   |

### Example
```
Afternoon Flow preset normally has 48 AI per player.

With 5 players:  48 AI each = 240 total AI (full traffic ✅)
With 22 players: 34 AI each = 748 total AI (30% reduction, smooth!)
```

### Key Features
- ✅ **Hot-reload**: No server restart needed
- ✅ **Seamless**: Players don't disconnect
- ✅ **Smart**: Only scales when needed
- ✅ **Safe**: Absolute limits (25-75 AI per player)

---

## 🗳️ System 2: Weighted Poll Voting

### What It Does
Collects player feedback on traffic quality and uses **smart weighting** to ensure fair representation from both regulars and newcomers.

### How to Vote
After **10 minutes** of playing, you'll see a poll in chat:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Hey PlayerName! Quick question:
How do you feel about the AI traffic?
Vote: /1 (worst) to /5 (best)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Just type one command:
- `/1` - Too aggressive/annoying
- `/2` - Not great
- `/3` - OK, needs work
- `/4` - Good!
- `/5` - Perfect! 🚗💨

### Smart Weighting System

**Your vote weight depends on how long you've played:**

| Session Time | Vote Weight | Example |
|--------------|-------------|---------|
| 10 minutes   | 0.33x       | Newbie, but counted! |
| 30 minutes   | 1.00x       | Baseline "trusted" weight |
| 60 minutes   | 2.00x       | Regular player |
| 120+ minutes | 3.00x       | Hardcore (capped at 3x) |
| 6 hours      | 3.00x       | Still capped (no dominance!) |

**Formula**: `weight = min(session_minutes / 30, 3.0)`

### Regular Player Badge ⭐
If you've played for **2+ hours total** AND joined **3+ times**, you get the **⭐ Regular** badge!
- Your opinion counts more (but fairly!)
- Shows you know the server well

### Fairness Rules
✅ **Newbies matter** - Their feedback counts (just weighted less)  
✅ **No dominance** - 3x cap prevents one player from taking over  
✅ **Experience counts** - Long-time players have more influence  
✅ **One vote per period** - Can vote again if traffic changes (every 6 hours)

### Example Vote Weighting
```
Morning Rush (06:00-12:00):
- Newbie (15 min):  Rating 2/5, Weight 0.5x  → Weighted: 1.0
- Regular (60 min): Rating 4/5, Weight 2.0x  → Weighted: 8.0
- Hardcore (6 hr):  Rating 5/5, Weight 3.0x  → Weighted: 15.0

Final Rating: (1.0 + 8.0 + 15.0) / (0.5 + 2.0 + 3.0) = 4.36/5

Without weighting: (2 + 4 + 5) / 3 = 3.67/5
The weighted system gives more credit to experienced opinions!
```

### Vote Confirmation
When you vote, you'll see:
```
✅ Thanks PlayerName! Glad you're enjoying the traffic! 🚗💨
   Vote weight: 2.1x ⭐ (Session: 63 min)
```

### Your Vote Data
Every vote stores:
- **Rating** (1-5)
- **Session duration** (for weighting)
- **Vote weight** (calculated automatically)
- **Traffic period** (night/morning/afternoon/evening)
- **Regular status** (⭐ badge)
- **Timestamp** (for trend analysis)

---

## 🔧 System 3: Poll-Based Auto-Tuning (Coming Soon!)

### What It Will Do
Analyze poll data over **3+ days** and suggest traffic adjustments based on player feedback.

### Safety Thresholds
- Need **5+ votes** minimum
- Need **8.0+ weighted votes** (effective votes)
- Need **3+ days** of consistent feedback
- Maximum **15% adjustment** per change
- Only **1 adjustment per 24 hours**

### Adjustment Logic
```
If rating < 3.0 (for 3+ days):
  → Reduce intensity:
    • Increase density 10-15% (more spacing)
    • Reduce AI count by 5-10
    • Reduce speed by 5-10 kph

If rating ≥ 4.5 (for 3+ days):
  → Increase intensity:
    • Decrease density 10% (more packed)
    • Increase AI count by 5
    • Increase speed by 5 kph
```

### Example
```
Morning Rush consistently rated 2.5/5 for 3 days:
  System suggests:
    Density: 0.80 → 0.90 (+12.5% spacing)
    AI count: 58 → 52 (-10% cars)
    Speed: 103 → 98 kph (-5%)
```

---

## 📈 Monitoring & Transparency

### Daily Statistics
All poll results are posted to **#daily-statistic** channel every day at 23:59 UTC, showing:
- **AI TRAFFIC FEEDBACK** section
- Average rating by traffic period
- Vote breakdown (1-5 stars)
- Visual bar chart 📊

### Real-Time Logs
Server owners can monitor:
```bash
# View dynamic traffic logs (auto-scaling)
tail -f /home/acserver/server/logs/dynamic_traffic.log

# Analyze poll data
python3 dynamic_traffic.py --poll-analysis
```

---

## 🎯 Why This System is Awesome

### For Players
✅ **Less lag** when server is full (auto-scaling)  
✅ **Your voice matters** (even as a newbie!)  
✅ **Fair voting** (no single player dominates)  
✅ **Transparent** (see your vote weight)  
✅ **Continuous improvement** (server learns from feedback)

### For Server Owners
✅ **Data-driven** decisions (not guessing!)  
✅ **Automatic** optimization (hands-free)  
✅ **Safe** adjustments (multiple safeguards)  
✅ **Production-ready** (no experimental code)  
✅ **Scalable** (works with any player count)

---

## 📋 Technical Details

### Traffic Periods (6-hour rotations)
- **🌙 Night Cruise** (00:00-05:59): Light traffic, slower pace
- **☀️ Morning Rush** (06:00-11:59): Dense, fast, aggressive
- **🌤️ Afternoon Flow** (12:00-17:59): Balanced
- **🌆 Evening Attack** (18:00-23:59): Aggressive, fast

### Data Storage
- **Traffic votes**: `/home/acserver/server/traffic_votes.json`
- **Player stats**: `/home/acserver/server/player_stats.json`
- **Dynamic traffic logs**: `/home/acserver/server/logs/dynamic_traffic.log`

### CLI Commands
```bash
# View schedule and scaling info
python3 dynamic_traffic.py --schedule

# Analyze poll data (suggestions only, no changes)
python3 dynamic_traffic.py --poll-analysis

# Apply current preset manually
python3 dynamic_traffic.py --apply-now
```

---

## ❓ FAQ

### Q: Can I vote multiple times per day?
**A:** Yes, but **once per traffic period** (every 6 hours). So max 4 votes per day.

### Q: Why does my vote weight show 0.5x?
**A:** You haven't played for 30 minutes yet. The system still counts your vote, just with less weight. Play longer and it increases!

### Q: What if I'm a regular but my vote shows 0.8x?
**A:** Vote weight is based on **current session time**, not your regular status. The ⭐ badge shows you're recognized as a regular, but weight comes from session length.

### Q: Can I see all vote data?
**A:** Server owners can view `traffic_votes.json` directly. Players see aggregated results in daily statistics.

### Q: What happens if there are no votes?
**A:** Nothing! The system waits for feedback. Default traffic presets remain active.

### Q: Does auto-scaling affect performance?
**A:** No! It **improves** performance by reducing AI when the server is crowded.

### Q: Can I disable the poll?
**A:** Server owners can adjust `POLL_DELAY_MINUTES` in `unified_announcer.py` or disable it entirely.

---

## 🙏 Credits

**Designed by**: RedLine Souls AI Team  
**Inspired by**: Community feedback and data science best practices  
**Goal**: Create the most optimized, fair, and engaging cruise server possible!

---

**Last Updated**: November 9, 2025  
**Version**: 1.0.0 (Initial Release)

