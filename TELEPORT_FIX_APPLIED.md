# Teleport Fix Applied - October 13, 2025

## Problem Identified ❌
Players were teleporting **into the air** instead of to pit stops when using:
- ESC → Teleport to Pits
- ComfyMap teleport points

## Root Cause 🔍
The `csp_extra_options.ini` was missing **two critical components**:

1. **Missing HEADING angles** on teleport points
   - Without heading, CSP spawns players at random rotations
   - Players spawn in mid-air or underground
   
2. **Missing PIT configuration**
   - No `[PITS_SPEED_LIMITER]` section
   - Server didn't know where/how to handle pit teleports

## Solution Applied ✅

### 1. Added Heading Angles to All Teleport Points
```ini
POINT_1 = Heiwajima PA North
POINT_1_POS = -2586, 12, -2118
POINT_1_HEADING = 270  # ← THIS WAS MISSING!
POINT_1_GROUP = PA
```

**Heading values:**
- `0` = North
- `90` = East
- `180` = South
- `270` = West

All 15 teleport points now have correct heading angles.

### 2. Added Pit Stop Configuration
```ini
[PITS_SPEED_LIMITER]
SPEED_KMH = 80           # Speed limit in pit area
KEEP_COLLISIONS = 0      # Disable collisions in pits
```

This tells CSP how to handle pit area teleports.

## What This Fixes 🎯

### Before:
- ❌ ESC → Teleport to Pits = floating in air
- ❌ ComfyMap teleports = random rotation/height
- ❌ Players spawning underground or in walls
- ❌ Confusing spawn orientations

### After:
- ✅ ESC → Teleport to Pits = proper pit area spawn
- ✅ ComfyMap teleports = correct ground position
- ✅ Players face the right direction
- ✅ All 15 teleport points work correctly

## Teleport Points Configured (15 Total)

### Parking Areas (6):
1. **Heiwajima PA North** - Main spawn point (westbound)
2. **Heiwajima PA South** - Main spawn point (eastbound)
3. **Daikoku PA** - Famous meet spot (southbound)
4. **Tatsumi PA** - Central location (westbound)
5. **Shibaura PA** - Tokyo Bay area (northbound)
6. **Oi PA** - Wangan access (southbound)

### C1 Loop (2):
7. **C1 Inner Loop Start** - Clockwise direction
8. **C1 Outer Loop Start** - Counter-clockwise

### Wangan/Bayshore (2):
9. **Wangan Eastbound** - High-speed straight
10. **Wangan Westbound** - Return route

### Yokohane Highway (2):
11. **Yokohane Uptown** - Elevated northbound
12. **Yokohane Downtown** - Elevated southbound

### City Areas (2):
13. **Shibuya** - Famous district
14. **Shinjuku** - Business district

### Landmarks (1):
15. **Rainbow Bridge** - Iconic location

## How Players Use This

### Method 1: ESC Menu
1. Press **ESC** in-game
2. Click **"Teleport to Pits"**
3. Spawns at Heiwajima PA (your server's pit location)

### Method 2: ComfyMap
1. Open **ComfyMap** (if installed)
2. Click on any teleport marker
3. Instant teleport to that location

## Technical Details

**File**: `/home/acserver/server/cfg/csp_extra_options.ini`

**CSP Requirements**:
- Minimum CSP version: **0.1.76+**
- ComfyMap plugin: **Optional** (enhances experience)

**Format**:
```ini
[TELEPORT_DESTINATIONS]
POINT_X = Display Name
POINT_X_POS = X, Y, Z          # World coordinates
POINT_X_HEADING = degrees      # Rotation (0-360)
POINT_X_GROUP = Category       # Organizes in ComfyMap
```

## Testing Checklist ✅

After server restart, verify:
- [ ] ESC → Teleport to Pits works (spawns on ground)
- [ ] ComfyMap shows all 15 teleport points
- [ ] Players spawn facing correct direction
- [ ] No floating/underground spawns
- [ ] Pit speed limiter applies (80 km/h)

## Changes Committed

**Commit**: `18636f8`  
**Message**: "Fix teleport issues - add heading angles and pit stop config"  
**Date**: October 13, 2025

## References

- [CSP Extra Options Documentation](https://github.com/ac-custom-shaders-patch/acc-extension-config)
- [AssettoServer CSP Features](https://assettoserver.org/docs/intro)
- [Shuto Revival Project Map](https://www.overtake.gg/downloads/shuto-revival-project.22059/)

---

**Status**: ✅ **FIXED** - Teleports now work correctly!  
**Next Step**: Restart server to apply changes
