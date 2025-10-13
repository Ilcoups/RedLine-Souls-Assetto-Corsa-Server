# Extensive Logging Enabled - Debugging Guide

**Enabled**: October 13, 2025 at 12:02 UTC  
**Server PID**: 107357

---

## 🔍 What's Now Being Logged

### 1. **Enhanced Debug Level Logging**
- **File**: `appsettings.json` (newly created)
- **Level**: `Debug` (most detailed)
- **Output**: All connection attempts, data transfers, protocol handshakes

### 2. **Client Message Debugging**
- **Enabled**: `DebugClientMessages: true`
- **Logs**: All CSP Lua messages, online events, custom client data
- **Useful for**: Seeing what clients are sending/receiving

### 3. **AI Traffic Debug Mode**
- **Enabled**: `Debug: true` in AiParams
- **Logs**: AI spawn decisions, pathfinding, obstacle detection
- **Useful for**: Understanding AI behavior issues

### 4. **IP Address Visibility**
- **Enabled**: `RedactIpAddresses: false`
- **Logs**: Full IP addresses for connection troubleshooting
- **Useful for**: Identifying network issues or specific players

### 5. **Welcome Message Debug Dumps**
- **Enabled**: `DebugWelcomeMessage: true`
- **Creates**: `debug_csp_extra_options.<sessionid>.ini` files
- **Useful for**: Seeing exact CSP options sent to each client

---

## 📋 What You'll See in Logs Now

### Connection Sequence (Full Detail):
```
[DBG] Player attempting connection from IP:PORT
[DBG] CSP version detected: X.X.X
[DBG] CSP features: [list of all supported features]
[DBG] Car checksums validated
[DBG] Track checksums validated
[DBG] Welcome message generated for player
[DBG] CSP extra options sent
[INF] Player connected
[DBG] Player position updates
[DBG] Network packets sent/received
[DBG] AI traffic adjustments
[DBG] Disconnection reason (if any)
```

### AI Traffic Details:
```
[DBG] AI Slot overbooking update
[DBG] AI spawn point selection
[DBG] AI obstacle detection
[DBG] AI speed calculations
[DBG] AI state changes
```

### Network Details:
```
[DBG] Packet types and sizes
[DBG] Position update frequency
[DBG] Checksum validations
[DBG] Custom update protocol usage
```

---

## 📊 How to Monitor Logs in Real-Time

### Watch All Activity:
```bash
tail -f ~/server/logs/log-$(date +%Y%m%d).txt
```

### Watch Only Connections:
```bash
tail -f ~/server/logs/log-$(date +%Y%m%d).txt | grep -E "connect|disconnect|attempt"
```

### Watch Errors/Warnings:
```bash
tail -f ~/server/logs/log-$(date +%Y%m%d).txt | grep -E "WRN|ERR|FTL"
```

### Watch Specific Player:
```bash
tail -f ~/server/logs/log-$(date +%Y%m%d).txt | grep "playername"
```

### Watch AI Traffic:
```bash
tail -f ~/server/logs/log-$(date +%Y%m%d).txt | grep "AI"
```

---

## 🔎 What to Look For

### When Someone Connects:

**1. Check Connection Handshake:**
- Does player successfully complete TCP handshake?
- Are CSP features properly detected?
- Does checksum validation pass?

**2. Check Data Transfer:**
- Is welcome message sent?
- Are CSP extra options received?
- Are position updates working?

**3. Check Disconnect Reason:**
- Client initiated? (normal quit)
- Server kicked? (timeout, checksum fail, etc.)
- Network error? (packet loss, timeout)

### If Quick Disconnects Continue:

Look for these patterns in logs:
- **Checksum mismatches**: Player has different file versions
- **CSP version issues**: Client CSP too old or missing features
- **Loading timeouts**: Player stuck on loading screen
- **Network errors**: Packet loss, high ping, connection drops
- **Track/car issues**: Missing content or corrupted files

---

## 🎯 Debug Commands You Can Use

### Check Recent Connections:
```bash
grep -E "attempting to connect|connected|disconnected" ~/server/logs/log-$(date +%Y%m%d).txt | tail -20
```

### Check All Errors Today:
```bash
grep -E "ERR|WRN|FTL" ~/server/logs/log-$(date +%Y%m%d).txt | tail -50
```

### Check Specific IP:
```bash
grep "79.116.141.186" ~/server/logs/log-$(date +%Y%m%d).txt
```

### Check CSP Features:
```bash
grep "CSP features" ~/server/logs/log-$(date +%Y%m%d).txt | tail -10
```

### Check AI Activity:
```bash
grep "AI Slot" ~/server/logs/log-$(date +%Y%m%d).txt | tail -20
```

---

## 📁 Debug Files Created

When someone connects, look for these debug files in `/home/acserver/server/cfg/`:

- `debug_csp_extra_options.<sessionid>.ini` - Exact CSP options sent to that player
- Check these to verify players are getting correct weather, track params, etc.

---

## ⚠️ Important Notes

### Performance Impact:
- Debug logging uses more CPU and disk I/O
- Log files will grow faster (check `logs/` folder size)
- Consider disabling after troubleshooting is complete

### Privacy:
- IP addresses are now visible in logs
- Be careful sharing log files publicly
- Player Steam IDs are logged

### Storage:
- Logs rotate daily automatically
- Kept for 7 days then deleted
- Monitor disk space: `df -h ~/server/logs/`

---

## 🔄 To Disable Extensive Logging Later

When you've identified the issue, restore normal logging:

1. **Edit `appsettings.json`**: Change `"Default": "Debug"` to `"Default": "Information"`
2. **Edit `cfg/extra_cfg.yml`**:
   - `DebugClientMessages: false`
   - `RedactIpAddresses: true`
   - AI `Debug: false`
3. **Restart server**: `./stop_server.sh && ./start_server.sh`

---

## 📞 What to Share If You Need Help

If someone still can't connect, capture this info:

1. **Full connection sequence** from logs (20-30 lines)
2. **Player's CSP version** (from log line)
3. **Any error messages** (ERR/WRN/FTL lines)
4. **Player's IP** (for geographic/routing issues)
5. **Disconnect reason** (client vs server initiated)

---

## ✅ Current Status

- **Extensive logging**: ✅ ENABLED
- **Debug level**: Debug (most detailed)
- **AI debug**: ✅ ENABLED
- **Client messages**: ✅ ENABLED
- **IP logging**: ✅ ENABLED (not redacted)
- **Welcome message dumps**: ✅ ENABLED

**Next connection will be logged in extreme detail!**

---

**Server is ready for detailed debugging. When the next player connects, we'll see everything!** 🔍
