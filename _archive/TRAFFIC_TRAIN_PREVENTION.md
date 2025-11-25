# Traffic Train/Convoy Prevention - Historical Solutions

## The Problem: Traffic Trains 🚂

**What were traffic trains?**
AI cars bunching up in long lines ("convoys") behind a single slow car, creating unrealistic traffic jams.

**Why it happened:**
1. Speed variation caused faster cars to catch slower ones
2. Cars stopped too long after collisions
3. Cars waited too long behind obstacles
4. Speed mismatches created permanent followers

---

## Solutions Applied (Before Dynamic Traffic)

### Commit 6fe1efc - November 1, 2025
**"Fix: AI traffic grounding and convoy prevention"**

#### Key Changes:

**1. Reduced Speed Variation**
```yaml
MaxSpeedVariationPercent: 0.30 → 0.20
```
- **Before**: 30% variation caused big speed differences
- **After**: 20% variation = more consistent speeds
- **Result**: Less bunching behind slower cars

**2. Fixed Floating Cars**
```yaml
SplineHeightOffsetMeters: 0.15 → 0.0
```
- **Before**: Cars floated 15cm above road (caused bouncing)
- **After**: Cars sit flush on road
- **Result**: Smooth movement, no weird physics

---

### Commit dbde677 - November 1, 2025
**"Fix: Anti-jam improvements - traffic flows, doesn't stop"**

#### Key Anti-Jam Settings:

**1. Faster Obstacle Ignore**
```yaml
IgnoreObstaclesAfterSeconds: 3 → 2 seconds
```
- **What it does**: After 2 seconds stuck behind slow car, AI drives through it
- **Result**: Traffic doesn't wait forever behind obstacles

**2. Faster AFK Player Ignore**
```yaml
PlayerAfkTimeoutSeconds: 5 → 3 seconds
```
- **What it does**: Ignores stationary/parked players faster
- **Result**: Traffic doesn't jam around pit areas

**3. Faster Acceleration**
```yaml
DefaultAcceleration: 3.0 → 4.5
```
- **What it does**: AI recovers from slowdowns quicker
- **Result**: Less bunching when traffic speeds up

---

### Commit 25d364b
**"Anti-jam traffic: AI ignores slow cars after 1 sec"**

#### Even More Aggressive Anti-Jam:

**1. Ultra-Fast Obstacle Ignore**
```yaml
IgnoreObstaclesAfterSeconds: 2 → 1 second
```
- **What it does**: AI only waits 1 second before driving through slow cars
- **Result**: Almost no traffic jams possible

**2. Minimal Collision Stops**
```yaml
MinCollisionStopTimeSeconds: 1 → 0
MaxCollisionStopTimeSeconds: 2 → 1
```
- **What it does**: AI barely stops after collisions (0-1 sec vs 1-2 sec)
- **Result**: Collisions don't create long traffic jams

---

## The Complete Anti-Train Solution

### Core Settings (Last Working Version)

```yaml
# From cfg/extra_cfg.yml before dynamic traffic

AiParams:
  # Speed consistency - prevents convoys
  MaxSpeedVariationPercent: 0.20  # Was 0.30
  
  # Anti-jam timings
  IgnoreObstaclesAfterSeconds: 1  # Drive through obstacles after 1 sec
  PlayerAfkTimeoutSeconds: 3      # Ignore AFK players after 3 sec
  
  # Collision behavior
  MinCollisionStopTimeSeconds: 0  # Don't stop...
  MaxCollisionStopTimeSeconds: 1  # ...or stop for 1 sec max
  
  # Recovery speed
  DefaultAcceleration: 4.5  # Fast recovery from slowdowns
  
  # Critical setting
  IgnoreStationaryPlayers: true  # Drive through parked players
  
  # Pit area exceptions
  IgnorePlayerObstacleSpheres:
    - X: 1735.0
      Z: -1670.0
      Radius: 150.0  # Heiwajima PA - traffic ignores ALL players
```

---

## How It Worked

### Before Fix:
```
[Fast Car] → 🐌 [Slow Car] → [Fast Car] → [Fast Car] → [Fast Car]
             ↑ Everyone stuck behind this guy!
```

### After Fix:
```
[Fast Car] passes through → 
🐌 [Slow Car] (alone)
[Fast Car] passes through →
[Fast Car] passes through →
```

**Key mechanics:**
1. Cars wait max 1 second behind obstacles
2. Then they "ignore" the obstacle and drive through
3. Collision stops last 0-1 seconds (not 1-2 seconds)
4. Speed variation reduced = less catching up

---

## Current vs Old Settings

| Setting | Old (Trains) | Fixed (No Trains) | Current (Dynamic) |
|---------|--------------|-------------------|-------------------|
| MaxSpeedVariation | 0.30 (30%) | 0.20 (20%) | 0.25 (25%) |
| IgnoreObstacles | 3 sec | 1 sec | 1 sec |
| PlayerAfkTimeout | 5 sec | 3 sec | 3 sec |
| CollisionStop | 1-2 sec | 0-1 sec | 1-2 sec (reverted) |
| DefaultAccel | 3.0 | 4.5 | 4.5 |

**Note**: Your current dynamic traffic has slightly relaxed collision stops (1-2 sec) for more realism, but kept the aggressive obstacle ignore (1 sec) to prevent trains.

---

## Files to Check

**Last working config before dynamic traffic:**

```bash
# View the exact config from that time
git show 6fe1efc:cfg/extra_cfg.yml | grep -A100 "AiParams:"

# View anti-jam commit
git show dbde677

# View ultra-aggressive anti-jam
git show 25d364b
```

---

## Key Takeaways

**The traffic train problem was solved by:**

1. ✅ **Lower speed variation** (20% instead of 30%)
2. ✅ **Aggressive obstacle ignore** (1 second, not 3-5 seconds)
3. ✅ **Minimal collision stops** (0-1 seconds, not 1-2 seconds)
4. ✅ **Fast acceleration** (4.5, not 3.0)
5. ✅ **Ignore stationary players** (critical!)

**Trade-off:**
- More aggressive = less realistic
- But prevents frustrating traffic jams
- Your dynamic traffic found a good balance

---

## If You Want to Restore Old Anti-Jam Settings

Update your `cfg/extra_cfg.yml`:

```yaml
AiParams:
  # Ultra-aggressive anti-jam (like before dynamic traffic)
  IgnoreObstaclesAfterSeconds: 1  # Currently 1 (good!)
  PlayerAfkTimeoutSeconds: 3       # Currently 3 (good!)
  MinCollisionStopTimeSeconds: 0   # Currently 1 (change to 0 for old behavior)
  MaxCollisionStopTimeSeconds: 1   # Currently 2 (change to 1 for old behavior)
  MaxSpeedVariationPercent: 0.20   # Currently 0.25 (change to 0.20 for old behavior)
```

Then restart server!
