# Dynamic Traffic System - Improvement Proposals

## Current System (GOOD ✓)
- 4 daily cycles (6-hour rotations): Night, Morning, Afternoon, Evening
- Automatic changes at 00:00, 06:00, 12:00, 18:00
- Hot-reload without server restart
- Auto-backups every change
- Checks every 30 minutes

## Proposed Improvements (EVEN BETTER 🚀)

### 1. **POLL-BASED AUTO-TUNING** ⭐ (TOP PRIORITY)
**What**: Use traffic poll feedback to automatically adjust settings
**How**: 
- Analyze daily poll results (we just added this!)
- If average rating < 3.0 → Reduce traffic density by 10%
- If average rating >= 4.5 → Can try more aggressive settings
- Track rating trends over time
- Make small incremental adjustments (not radical changes)

**Benefits**:
- Self-optimizing based on REAL player feedback
- Continuous improvement without manual tuning
- Data-driven decisions

**Implementation**:
```python
def analyze_poll_feedback():
    # Read traffic_votes.json
    # Calculate average rating for each time period
    # If morning rush rating < 3.0:
    #   - Reduce morning density from 0.80 → 0.90
    #   - Reduce AI count from 58 → 50
    # Save adjustment log
```

---

### 2. **PLAYER COUNT ADAPTIVE** ⭐
**What**: Scale AI traffic based on current server load
**How**:
- Query /api/details for current player count
- If players < 10 → Use full AI count
- If players > 20 → Reduce AI by 20% (prevent lag)
- If players > 25 → Reduce AI by 30%
- Dynamic adjustment every 5 minutes

**Benefits**:
- Prevents server overload during peak hours
- Maintains performance for full servers
- More AI when server is empty (better experience)

**Implementation**:
```python
def get_player_scaled_ai_count(base_ai_count, current_players):
    if current_players < 10:
        return base_ai_count
    elif current_players < 20:
        return int(base_ai_count * 0.90)
    elif current_players < 25:
        return int(base_ai_count * 0.80)
    else:
        return int(base_ai_count * 0.70)
```

---

### 3. **FPS-BASED AUTO-SCALING** ⭐
**What**: Monitor player FPS from analytics, reduce traffic if struggling
**How**:
- Use PatreonAnalyticsPlugin metrics (/metrics endpoint)
- Read average FPS from `assettoserver_client_fps{quantile="0.5"}`
- If avg FPS < 40 → Reduce traffic by 15%
- If avg FPS < 30 → Reduce traffic by 30%
- If avg FPS > 55 → Can increase traffic

**Benefits**:
- Automatic performance optimization
- Prevents bad experience for low-end players
- Uses existing analytics data

**Implementation**:
```python
def get_fps_scaled_modifier():
    avg_fps = get_median_fps_from_metrics()
    if avg_fps < 30:
        return 0.70  # Reduce to 70%
    elif avg_fps < 40:
        return 0.85  # Reduce to 85%
    elif avg_fps > 55:
        return 1.10  # Can increase 10%
    return 1.0
```

---

### 4. **WEEKEND vs WEEKDAY PATTERNS** ⭐
**What**: Different traffic schedules for weekends
**How**:
- Weekday: Current 4-cycle pattern (work commute simulation)
- Weekend: More relaxed, less "morning rush", more "cruise" time
- Saturday: Afternoon starts earlier (11:00), evening more aggressive
- Sunday: Light traffic all day (cruise day)

**Benefits**:
- More realistic (no rush hour on Sunday!)
- Variety keeps gameplay fresh
- Players know "Sunday = chill drives"

**Example Weekend Schedule**:
```
Saturday:
  00-08: Night Cruise (light)
  08-14: Morning Flow (moderate, not rush)
  14-20: Afternoon Attack (aggressive)
  20-24: Evening Cruise (moderate)

Sunday:
  00-24: All-Day Cruise (light, relaxed)
```

---

### 5. **WEATHER-RESPONSIVE TRAFFIC**
**What**: Adjust traffic behavior based on weather
**How**:
- Read current weather from extra_cfg.yml
- If rain → Reduce speed by 15%, increase spacing by 20%
- If fog → Reduce AI count by 20%
- If clear → Normal settings

**Benefits**:
- More realistic (people drive slower in rain!)
- Better gameplay variety
- Weather becomes more impactful

---

### 6. **GRADUAL TRANSITIONS** (Advanced)
**What**: Smooth transitions instead of instant changes
**How**:
- Over 15 minutes, gradually blend old → new settings
- Example: 05:45 → 06:15 transition from Night → Morning
- Prevents sudden traffic behavior changes

**Benefits**:
- More realistic (traffic doesn't change instantly)
- Smoother player experience
- Less jarring

---

### 7. **SPECIAL EVENT PRESETS**
**What**: Manually triggerable special traffic modes
**How**:
- Race event: Clear highways (very light traffic)
- Cruise event: Balanced, predictable traffic
- Chaos mode: Maximum density, maximum chaos
- Empty server: Minimal AI to save resources

**Commands**:
```bash
python3 dynamic_traffic.py --event race
python3 dynamic_traffic.py --event cruise
python3 dynamic_traffic.py --event chaos
python3 dynamic_traffic.py --event empty
python3 dynamic_traffic.py --resume-schedule  # back to normal
```

---

### 8. **MACHINE LEARNING** (Future)
**What**: Learn optimal settings from historical poll data
**How**:
- Track: time of day, day of week, player count, traffic settings, poll rating
- Use simple linear regression to predict best settings
- Gradually optimize over weeks/months

**Benefits**:
- Truly data-driven optimization
- Learns player preferences over time
- Self-improving system

---

## Recommended Implementation Order

### Phase 1: Immediate (This Week)
1. **Poll-Based Auto-Tuning** - We have the data now!
2. **Player Count Adaptive** - Simple and effective

### Phase 2: Short Term (Next Week)
3. **FPS-Based Auto-Scaling** - Use analytics we just added
4. **Weekend vs Weekday** - Easy schedule change

### Phase 3: Medium Term (This Month)
5. **Weather-Responsive** - Moderate complexity
6. **Special Event Presets** - Nice-to-have

### Phase 4: Long Term (Future)
7. **Gradual Transitions** - Polish
8. **Machine Learning** - Advanced optimization

---

## Questions to Consider

1. **How aggressive should poll-based tuning be?**
   - Conservative: 10% adjustments
   - Moderate: 20% adjustments
   - Aggressive: 30% adjustments

2. **Should we notify players of traffic changes?**
   - In-game chat: "🚗 Traffic adjusted based on player feedback!"
   - Discord: Daily report of changes made

3. **Should we allow player voting on traffic presets?**
   - Poll: "Which time period needs adjustment?"
   - Democratic traffic tuning

4. **Safety limits?**
   - Minimum AI count: 20 per player
   - Maximum AI count: 80 per player
   - Prevent extreme settings

---

## Metrics to Track

For measuring improvement success:
- Average poll rating per time period
- Player count during each period
- Average FPS during each period
- Collision rates (from analytics)
- Player session duration
- Repeat player rate

---

**Your Thoughts?**

Which improvements sound most valuable to you?
Should I start implementing any of these?

