# ✅ VIP & Admin System - Setup Complete!

## 👑 Administrators

### il (Server Owner)
- **Steam ID:** `76561199185532445`
- **File:** `cfg/admins.txt`
- **Permissions:**
  - Full server admin access
  - Can kick/ban players
  - Can use admin commands
  - Reserved slot (server never full for you)
  - Red [ADMIN] tag in chat

**Chat appearance:**
```
[ADMIN] il: Hello everyone! 
```
Color: Red (#FF0000)

---

## 💎 VIP Members

### N7
- **Steam ID:** `76561198167417502`
- **File:** `cfg/vips.txt`
- **Permissions:**
  - Reserved VIP slot (4 total reserved)
  - Gold [VIP] tag in chat
  - Can join when server shows "full"
  - Priority connection

**Chat appearance:**
```
[VIP] N7: Nice overtake!
```
Color: Gold (#FFD700)

---

## 🎨 Chat Role System

### Active Roles (PatreonChatRolesPlugin)

| Role | Prefix | Color | User Group |
|------|--------|-------|------------|
| Admin | `[ADMIN]` | Red (#FF0000) | default_admins |
| VIP | `[VIP]` | Gold (#FFD700) | vips |
| Regular | None | White (#FFFFFF) | default |

### How It Works:
- Admins always get red [ADMIN] tag
- VIPs always get gold [VIP] tag
- Regular players have no prefix
- Color applies to player name in chat
- Tags are automatic - no commands needed

---

## 🎫 Reserved Slots System

### Configuration (PatreonReservedSlotsPlugin)

**Total Reserved Slots:** 4
- Admins: Can always join
- VIPs: Can always join

**How It Works:**
1. Server max capacity: 32 players
2. Public slots: 28
3. Reserved slots: 4 (for admins + VIPs)
4. When you try to join a "full" server:
   - If you're admin/VIP: You get in
   - Lowest priority player gets kicked automatically
   - You take their slot

**Priority Order:**
1. Admins (highest)
2. VIPs
3. Regular players (lowest)

---

## 📁 User Group Files

### Location: `/home/acserver/server/cfg/`

#### admins.txt
```
# RedLine Souls - Server Admins
76561199185532445  # il
```

#### vips.txt
```
# RedLine Souls - VIP Players
76561198167417502  # N7
```

### Adding More Users:
1. Get their Steam64 ID
2. Add to appropriate file (one ID per line)
3. Restart server
4. They automatically get permissions!

---

## 🔧 Configuration Files

### extra_cfg.yml Changes:

#### User Groups (Lines 65-69):
```yaml
UserGroups:
  default_blacklist: blacklist.txt
  default_whitelist: whitelist.txt
  default_admins: admins.txt
  vips: vips.txt  # NEW!
```

#### Chat Roles (Lines 305-316):
```yaml
!PatreonChatRolesConfiguration
Roles:
  - UserGroup: default_admins
    Prefix: "[ADMIN]"
    Color: "#FF0000"
  - UserGroup: vips  # NEW!
    Prefix: "[VIP]"
    Color: "#FFD700"  # Gold
  - UserGroup: default
    Prefix: ""
    Color: "#FFFFFF"
```

#### Reserved Slots (Lines 319-324):
```yaml
!PatreonReservedSlotsConfiguration
ReservedSlots: 4  # Increased from 2
UserGroups:
  - default_admins
  - vips  # NEW!
```

---

## 🎮 What You'll See In-Game

### When You (il) Join:
1. Server recognizes you as admin
2. You get red [ADMIN] tag
3. You can join even if server is "full"
4. All admin commands available
5. Chat messages appear in red

### When N7 Joins:
1. Server recognizes them as VIP
2. They get gold [VIP] tag
3. They can join even if server is "full"
4. Chat messages appear in gold
5. Reserved slot priority

### When Regular Players Join:
1. Normal connection process
2. No special prefix
3. White name in chat
4. Can be kicked if server full and VIP/admin joins

---

## 💬 Discord Integration

All leaderboards and features still work:
- ✅ Overtake leaderboard
- ✅ Speed trap violations
- ✅ Safety ratings
- ✅ Time attack leaderboards
- ✅ Race challenges

**Discord Bot Status:** ✅ Connected & Ready

**Commands available:**
- `/overtake-leaderboard`
- `/timing-leaderboard`
- `/server-status`

---

## 📊 Current Server Status

### Active Plugins: 11 Total
1. ✅ RandomWeatherPlugin
2. ✅ PatreonHubPlugin
3. ✅ PatreonOvertakePlugin
4. ✅ PatreonSpeedTrapPlugin
5. ✅ PatreonTimingPlugin
6. ✅ PatreonSafetyRatingPlugin
7. ✅ PatreonRaceChallengePlugin
8. ✅ PatreonChatRolesPlugin (handles VIP colors!)
9. ✅ PatreonReservedSlotsPlugin (handles VIP slots!)
10. ✅ PatreonAnalyticsPlugin

### User Groups Loaded:
- ✅ default_admins (1 member: il)
- ✅ vips (1 member: N7)
- ✅ default_blacklist (empty)
- ✅ default_whitelist (empty)

### Discord:
- ✅ Bot connected
- ✅ Commands registered
- ✅ Leaderboards active
- ✅ Auto-updates working

---

## 🧪 How to Test

### Test Admin Powers (il):
1. Join server
2. Check your chat name is red with [ADMIN]
3. Try admin commands in chat
4. You should have full control

### Test VIP Status (N7):
1. Join server
2. Check your chat name is gold with [VIP]
3. You have reserved slot access
4. Try chatting to see gold name

### Test Reserved Slots:
1. Get 28+ regular players on server
2. Try joining as VIP/admin
3. You should get in automatically
4. Lowest priority player gets kicked

---

## 🎯 Adding More VIPs/Admins

### To Add Admin:
1. Get their Steam64 ID (from logs or website)
2. Edit `cfg/admins.txt`
3. Add their Steam ID (one per line)
4. Restart server or wait for file reload
5. Done!

### To Add VIP:
1. Get their Steam64 ID
2. Edit `cfg/vips.txt`
3. Add their Steam ID (one per line)
4. Restart server
5. They get gold [VIP] tag automatically!

### Finding Steam64 IDs:
- Check server logs: `tail -f logs/log-$(date +%Y%m%d).txt`
- Or use: https://steamid.io/
- Or check `player_stats.json`

---

## 🎨 Customizing Colors/Tags

### Want Different Colors?
Edit `cfg/extra_cfg.yml` → `!PatreonChatRolesConfiguration`:

**Popular color codes:**
- Red: `#FF0000` (current admin)
- Gold: `#FFD700` (current VIP)
- Blue: `#0000FF`
- Green: `#00FF00`
- Purple: `#9B59B6`
- Orange: `#FF8C00`
- Pink: `#FF1493`
- Cyan: `#00FFFF`

### Want Different Prefixes?
Change `Prefix:` to anything:
- `[OWNER]`
- `[PATRON]`
- `[MODERATOR]`
- `[PRO]`
- `★ VIP ★`
- `🔥 LEGEND 🔥`

**After changes:** Restart server!

---

## 🏆 Advanced: Discord Role Sync (Future)

### Possible Future Features:
1. Auto-assign Discord roles based on in-game roles
2. VIP role in Discord = VIP in server
3. Leaderboard-based role rewards
4. Achievement roles

**Not implemented yet, but possible with custom scripts!**

---

## 📋 Quick Reference

### File Locations:
```
/home/acserver/server/
├── cfg/
│   ├── admins.txt          # Admin Steam IDs
│   ├── vips.txt            # VIP Steam IDs  
│   └── extra_cfg.yml       # Main config (role colors, slots)
└── hub/
    └── Hub.db              # Leaderboard database
```

### Commands:
```bash
# View admins
cat cfg/admins.txt

# View VIPs
cat cfg/vips.txt

# Add admin (replace STEAM_ID)
echo "STEAM_ID" >> cfg/admins.txt

# Add VIP
echo "STEAM_ID" >> cfg/vips.txt

# Restart server
./stop_server.sh && ./start_server.sh
```

---

## ✅ Verification Checklist

- [x] Admin file created (cfg/admins.txt)
- [x] VIP file created (cfg/vips.txt)
- [x] User groups added to extra_cfg.yml
- [x] Chat roles configured (red admin, gold VIP)
- [x] Reserved slots updated (4 slots for admin+VIP)
- [x] Server restarted with new config
- [x] All 10 plugins loaded successfully
- [x] Discord bot connected and ready
- [x] Leaderboards active and updating

---

## 🎉 Status: COMPLETE!

**You are now admin!** 🔴 [ADMIN]
**N7 is now VIP!** 💛 [VIP]

**What's Active:**
- ✅ Admin powers and red tag
- ✅ VIP gold tag and reserved slot
- ✅ 4 reserved slots for admins + VIPs
- ✅ All 10 Patreon plugins running
- ✅ Discord bot with all features
- ✅ Chat role colors working
- ✅ Priority connection system

**Next time you join, you'll see your red [ADMIN] tag! 😈**

---

Need to add more VIPs or change colors? Just ask! 🚀

