# Balanced Traffic Settings - No Trains + No Aggressive Hits

## Current Issues Analysis

### Your Current Settings:
```yaml
IgnoreObstaclesAfterSeconds: 1      # ⚠️ TOO aggressive - causes hits
MaxSpeedVariationPercent: 0.25       # ⚠️ Slightly high - allows trains
PlayerRadiusMeters: 700              # ✅ GOOD
DefaultDeceleration: 5.0             # ✅ GOOD  
MinCollisionStopTimeSeconds: 1       # ✅ GOOD
MaxCollisionStopTimeSeconds: 2       # ✅ GOOD
```

### What's Wrong:
1. **IgnoreObstacles: 1 sec** = AI drives through you too fast
2. **SpeedVariation: 0.25 (25%)** = Some trains still form

### What's Right:
1. PlayerRadius: 700m = AI sees you from far away ✅
2. Deceleration: 5.0 = Smooth braking ✅
3. Collision stops: 1-2 sec = Good balance ✅

---

## The Perfect Balance

### Change These 2 Settings:

```yaml
# In cfg/extra_cfg.yml under AiParams:

# CHANGE 1: Less aggressive obstacle ignore
IgnoreObstaclesAfterSeconds: 2  # Was 1, now 2 - gives AI time to brake

# CHANGE 2: Lower speed variation  
MaxSpeedVariationPercent: 0.20  # Was 0.25, now 0.20 - prevents trains
```

**That's it!** Just 2 small changes give you the perfect balance.

---

## Why This Works

### Old Anti-Train Fix (Too Aggressive):
- Obstacle ignore: **1 second** → AI rams you
- Speed variation: **20%** → No trains but too uniform

### Old Pre-Dynamic (Trains Possible):
- Obstacle ignore: **2 seconds** → Safe but some trains
- Speed variation: **20%** → Good

### Your Current Dynamic:
- Obstacle ignore: **1 second** → Too aggressive! ❌
- Speed variation: **25%** → Allows some trains ❌

### **RECOMMENDED BALANCED**:
- Obstacle ignore: **2 seconds** → Safe braking time ✅
- Speed variation: **20%** → No trains ✅

---

## Expected Results

### Before (Current):
- ✅ No traffic trains
- ❌ AI sometimes hits you
- ⚠️ Too aggressive

### After (Balanced):
- ✅ No traffic trains (20% speed variation prevents them)
- ✅ AI brakes in time (2 second obstacle ignore)  
- ✅ Still flows well (not too passive)

---

## Full Recommended Config

```yaml
AiParams:
  # Player awareness (KEEP - already good!)
  PlayerRadiusMeters: 700
  PlayerAfkTimeoutSeconds: 3
  
  # Anti-train while being safe (CHANGE THESE!)
  IgnoreObstaclesAfterSeconds: 2      # Was 1 → Change to 2
  MaxSpeedVariationPercent: 0.20      # Was 0.25 → Change to 0.20
  
  # Braking (KEEP - already good!)
  DefaultDeceleration: 5.0
  DefaultAcceleration: 4.5
  
  # Collision behavior (KEEP - already good!)
  MinCollisionStopTimeSeconds: 1
  MaxCollisionStopTimeSeconds: 2
  
  # Everything else: KEEP AS IS
```

---

## Implementation

Run these commands:

```bash
cd /home/acserver/server

# Backup current config
cp cfg/extra_cfg.yml cfg/extra_cfg.yml.backup_$(date +%Y%m%d_%H%M%S)

# Change obstacle ignore from 1 to 2
sed -i 's/IgnoreObstaclesAfterSeconds: 1/IgnoreObstaclesAfterSeconds: 2/' cfg/extra_cfg.yml

# Change speed variation from 0.25 to 0.20
sed -i 's/MaxSpeedVariationPercent: 0.25/MaxSpeedVariationPercent: 0.20/' cfg/extra_cfg.yml

# Restart server
./restart_all.sh
```

---

## Testing

After applying changes:

1. **Drive on highway** - AI should not form trains behind slow cars
2. **Brake suddenly** - AI should stop in time, not hit you
3. **Park on side** - After 2 seconds, AI drives around you (not instant)

---

## Comparison Table

| Setting | Too Aggressive | TOO PASSIVE | **BALANCED** |
|---------|---------------|-------------|--------------|
| Obstacle Ignore | 1 sec | 3+ sec | **2 sec ✅** |
| Speed Variation | 15% | 30%+ | **20% ✅** |
| Player Radius | 450m | 1000m+ | **700m ✅** |
| Collision Stops |  0-1 sec | 3-5 sec | **1-2 sec ✅** |

Your current: Too Aggressive column
Recommended: BALANCED column

---

## Why These Specific Values?

### IgnoreObstacles: 2 seconds (not 1, not 3)
- **1 second**: Not enough time for AI to brake at speed
- **2 seconds**: Perfect - time to brake OR go around
- **3 seconds**: Too long - creates traffic jams

### SpeedVariation: 20% (not 15%, not 25%)
- **15%**: Too uniform, boring, robotic
- **20%**: Sweet spot - variety without trains
- **25%**: Too much - fast cars catch slow cars = trains

### Already Perfect:
- **PlayerRadius: 700m** - AI sees you early enough to react
- **Deceleration: 5.0** - Smooth, realistic braking
- **Collision: 1-2 sec** - Stops but doesn't jam

---

Ready to apply? Just 2 lines to change!
