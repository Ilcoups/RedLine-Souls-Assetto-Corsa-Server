# 🔍 QUICK DEBUG REFERENCE CARD

## ✅ Extensive Logging is NOW ACTIVE

**When**: Since 12:02 UTC, October 13, 2025  
**What**: Every connection attempt will be logged in extreme detail

---

## 🚨 WATCH FOR NEXT CONNECTION IN REAL-TIME

Open a new terminal and run:
```bash
tail -f ~/server/logs/log-$(date +%Y%m%d).txt | grep --color -E "connect|disconnect|Error|ERR|WRN"
```

This will show you:
- ✅ Connection attempts (with full IP and CSP version)
- ✅ What features the client supports
- ✅ Any errors or warnings
- ✅ Disconnect reasons

---

## 📋 WHAT CHANGED

### Before (Normal Logging):
```
[INF] Player connected
[INF] Player disconnected
```

### After (Debug Logging) - YOU'LL SEE:
```
[DBG] Player 79.116.141.186:12345 attempting connection
[DBG] CSP version: 2144 detected
[DBG] CSP features: [STEAM_TICKET, CLIENT_MESSAGES, WEATHERFX_V2, ...]
[DBG] Validating car checksums...
[DBG] Validating track checksums...
[DBG] Sending welcome message...
[DBG] Sending CSP extra options...
[INF] Player connected
[DBG] Position updates starting...
[DBG] Network packets: sent X, received Y
[DBG] Player initiated disconnect
[INF] Player disconnected
```

**10x MORE DETAIL** for every connection!

---

## 🎯 QUICK CHECKS

### See if anyone is trying RIGHT NOW:
```bash
grep "attempting to connect" ~/server/logs/log-$(date +%Y%m%d).txt | tail -5
```

### Check last disconnect reason:
```bash
grep -B 2 "disconnected" ~/server/logs/log-$(date +%Y%m%d).txt | tail -10
```

### See all errors in last hour:
```bash
grep "$(date -u +%Y-%m-%d)" ~/server/logs/log-$(date +%Y%m%d).txt | grep -E "ERR|WRN" | tail -20
```

---

## 💡 WHAT YOU'LL LEARN

When the next player connects (even for 6 seconds), you'll know:

1. **Their exact CSP version** - Is it too old?
2. **What features they support** - Missing CUSTOM_UPDATE?
3. **Checksum status** - Do their files match?
4. **Loading progress** - Did they get stuck?
5. **Why they disconnected** - Client choice or error?
6. **Network quality** - Packet loss? High ping?

**EVERYTHING IS LOGGED NOW!**

---

## 📊 CURRENT STATUS

- ✅ Debug level logging: **ENABLED**
- ✅ AI debug overlay: **ENABLED** 
- ✅ Client messages: **LOGGED**
- ✅ IP addresses: **VISIBLE**
- ✅ CSP options: **DUMPED TO FILES**

**Next player will generate 50-100 log lines instead of 2!**

---

## 🔄 When You're Done Debugging

After you figure out the issue:
```bash
# Restore normal logging
# See EXTENSIVE_LOGGING_GUIDE.md for full instructions
```

---

**Server is now in FULL DEBUG MODE. Wait for next connection attempt!** 🔎🚀
