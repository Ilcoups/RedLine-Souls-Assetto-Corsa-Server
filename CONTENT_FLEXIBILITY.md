# Content Flexibility & Compatibility Guide

This server is configured to be **highly tolerant** of different car and track versions to maximize player compatibility while maintaining fair gameplay.

## 🔓 What's Allowed

### ✅ Track Variations
- **Different track file versions** - Players with older/newer SRP versions can join
- **Missing track files** - Some optional track files (like reverb.kn5) don't need to match exactly
- **Modified track graphics** - Visual mods to the track are allowed

### ✅ Car Variations
- **Different car skins** - Any livery/skin works
- **Modified car sounds** - Custom sound mods are fine
- **Different data.acd versions** - Encrypted car data doesn't need to match exactly
- **Minor physics tweaks** - Small car setup differences are tolerated

### ✅ Client Mods
- **Custom Shaders Patch (CSP)** - Any CSP 0.1.76+ version works
- **Sol weather mod** - Optional, not required
- **Graphics mods** - Pure Reshade, filters, etc. are allowed
- **UI mods** - Custom UI apps and overlays work

## ⚙️ Server Configuration

### In `server_cfg.ini`:
```ini
DISABLE_CHECKSUMS=1  # Don't enforce strict file matching
```

### In `extra_cfg.yml`:
```yaml
IgnoreConfigurationErrors:
  MissingCarChecksums: true        # Allow cars without checksums
  MissingTrackParams: true         # Allow tracks without timezone data
  WrongServerDetails: true         # Ignore minor config issues

IgnoreMissingCarData: true         # Allow missing/different data.acd
IgnoreCarPhysicsMismatch: true     # Tolerate minor physics differences

PlayerChecksumTimeoutSeconds: 60   # Give players time to load
PlayerLoadingTimeoutMinutes: 15    # Don't rush slow connections

KickPacketLoss: 0                  # Don't kick for network hiccups
MaxPing: 500                       # Allow high ping players
```

## 🚫 What's NOT Allowed

Even with flexibility enabled, these will still cause issues:

### ❌ Completely Wrong Content
- **Wrong track entirely** - Must be `shuto_revival_project_beta`
- **Unlisted cars** - Must use one of the server's allowed cars
- **No CSP** - Custom Shaders Patch 0.1.76+ is required for WeatherFX

### ❌ Major Physics Exploits
- **Extreme car modifications** - Massively overpowered cars will be obvious
- **Collision exploits** - Cars that phase through walls won't work properly
- **Speed hacks** - Server still detects impossible speeds

## 🎯 Why This Approach?

### Benefits:
1. **More players can join** - Don't need exact same files
2. **Easier content updates** - SRP updates don't break the server
3. **Community friendly** - People with different mod setups can play together
4. **Less troubleshooting** - Fewer "checksum failed" kicks

### Trade-offs:
- **Visual inconsistencies** - Players might see slightly different things
- **Minor physics differences** - Not a competitive racing server, so this is fine
- **Requires trust** - Players could theoretically use modified cars (but obvious cheating is detectable)

## 📝 For Players

### To Join You Need:
1. **Assetto Corsa** + Content Manager
2. **Custom Shaders Patch 0.1.76+**
3. **Shuto Revival Project Beta track** (any recent version)
4. **One car from the server list** (any skin/variant)

### You DON'T Need:
- ❌ Exact same track files as the server
- ❌ Exact same car data.acd encryption
- ❌ Sol weather mod
- ❌ Specific CSP version (as long as 0.1.76+)

## 🔧 Troubleshooting

### "Checksum Failed" Errors
This shouldn't happen anymore! If it does:
1. Check you have the right **track** (shuto_revival_project_beta)
2. Check you have an **allowed car**
3. Update CSP to 0.1.76 or newer

### Connection Drops
- Server now tolerates packet loss
- High ping (up to 500ms) is allowed
- 15-minute loading timeout for slow connections

### AI Traffic Not Visible
- Some car/track combinations hide AI
- Make sure CSP is enabled and updated
- Check traffic settings in CSP options

## 🎮 Gameplay Impact

This flexible setup is **perfect for**:
- 🏙️ Casual cruising servers
- 🚗 Traffic/free-roam sessions  
- 🌍 International communities (different versions/regions)
- 🔄 Servers that update content frequently

This is **NOT recommended for**:
- 🏁 Competitive racing leagues
- ⚖️ Strict physics-based competitions
- 📊 Leaderboard/time attack servers

---

**Bottom line**: This server prioritizes **accessibility and fun** over strict enforcement. As long as you have the basic required content, you can join and enjoy the drive! 🚀
