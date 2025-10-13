# Comprehensive Disconnect Tracking - RedLine Souls AC Server

## What We're Tracking Now

### Enhanced Logging Levels
- **Verbose**: Maximum detail on all network operations
- **Connection lifecycle**: Every step from attempt to disconnect
- **Error reasons**: Exact cause of disconnections
- **Timeout tracking**: Loading timeouts, checksum timeouts, ping issues

### Key Metrics Being Logged
1. **Connection Attempts**: Who tries to join, their IP, CSP version
2. **Handshake Details**: Full CSP feature list, car selection, Steam ID
3. **Loading Progress**: How long they spend loading
4. **Spawn Success**: Did they successfully spawn on track?
5. **Disconnect Reason**: Why they left (timeout, kick, voluntary quit, error)
6. **Session Duration**: Exact time spent on server

## Extended Timeouts for Debugging
- **PlayerLoadingTimeoutMinutes**: 5 → 10 minutes
- **PlayerChecksumTimeoutSeconds**: 40 → 120 seconds

These longer timeouts ensure we see the REAL reason for disconnects, not just timeout kicks.

## Disconnect Reason Categories

### Quick Disconnects (< 30 seconds)
**Possible Causes:**
- Missing content (track/car files)
- CSP version incompatibility 
- Checksum mismatch (should be prevented by our config)
- Connection timeout
- Server full/kicked
- Client crash
- **Checking empty server** (11-15 seconds is typical "check and leave")

### Pit-Only Disconnects (30-90 seconds)
**Possible Causes:**
- Can't see AI traffic
- Track loading issues
- Performance problems
- UI/HUD not working
- **Empty server** (waited in pit, nobody joined)

### Mid-Session Disconnects (> 90 seconds)
**Possible Causes:**
- Network instability
- Kicked for AFK/ping/packet loss
- Game crash
- Voluntary quit after driving

## Monitoring Commands

### Real-Time Connection Monitoring
```bash
# Watch all connection activity
tail -f /home/acserver/server/logs/log-$(date +%Y%m%d).txt | grep -E "attempting to connect|has connected|has disconnected|Disconnecting"

# Watch for errors only
tail -f /home/acserver/server/logs/log-$(date +%Y%m%d).txt | grep -E "ERR|WRN|Exception|timeout"

# Full player lifecycle
tail -f /home/acserver/server/logs/log-$(date +%Y%m%d).txt | grep -v "AI Slot overbooking"
```

### Post-Connection Analysis
```bash
# Get full details for specific player
grep -A 20 -B 5 "PlayerName" /home/acserver/server/logs/log-*.txt

# Count disconnects by type
grep "has disconnected" /home/acserver/server/logs/log-$(date +%Y%m%d).txt | wc -l

# Find all errors/warnings today
grep -E "ERR|WRN" /home/acserver/server/logs/log-$(date +%Y%m%d).txt
```

## What To Look For in Logs

### Successful Connection Pattern
```
[INF] PlayerName (...) is attempting to connect (car_name)
[DBG] PlayerName supports extra CSP features: [...]
[INF] PlayerName (..., slot_number (car_name)) has connected
[DBG] AI Slot overbooking update - No. players: 1 - No. AI Slots: 52 - Target AI count: 7
```

### Problem Indicators

#### Missing Content
```
[WRN] PlayerName - Missing car data.acd
[ERR] Content mismatch detected
```

#### Checksum Issues
```
[WRN] Checksum timeout for PlayerName
[ERR] Failed to validate checksums
```

#### Network Problems
```
[WRN] PlayerName exceeded max ping
[WRN] High packet loss detected
```

#### CSP Version Issues
```
[ERR] Required CSP feature not supported
[WRN] CSP version too old
```

## Understanding Session Durations

### Duration Guide
- **< 10 seconds**: Connection failed during handshake/loading
- **10-15 seconds**: Loaded, checked server was empty, left
- **15-30 seconds**: Spawned in pit, saw no traffic/players, left
- **30-60 seconds**: Tested driving, something didn't work as expected
- **1-5 minutes**: Drove around, nobody else joined, left
- **> 5 minutes**: Actually racing/cruising

### VersusGame Example (11 seconds)
```
12:17:54 - Attempting to connect
12:17:54 - CSP features detected (CUSTOM_UPDATE, WEATHERFX_V3)
12:17:54 - Has connected (slot 44, Pagani Huayra BC)
12:18:05 - Disconnecting (11 seconds total)
12:18:05 - Has disconnected
```

**Analysis**: 11 seconds = Successfully loaded, spawned in pit, saw empty server, quit immediately. **This is normal behavior**, not a server issue.

## Next Steps After Detection

### If Pattern Shows < 15 Second Disconnects
✅ **Normal** - Players checking if server is populated

### If Pattern Shows 15-60 Second Disconnects
⚠️ **Investigate**:
- Check if AI traffic is visible to clients
- Verify track/car content matches
- Test CSP features work for clients
- Check for client-side errors

### If Pattern Shows Errors in Logs
🔴 **Action Required**:
- Fix missing content
- Adjust CSP requirements
- Check network configuration
- Review server performance

## Current Configuration Status
- ✅ Verbose logging enabled (maximum detail)
- ✅ Network logging at Verbose level
- ✅ AI logging at Debug level
- ✅ Extended timeouts (10 min loading, 120 sec checksum)
- ✅ CSP compatibility: 0.1.76+ (WeatherFX)
- ✅ Content flexibility: checksums disabled, mismatch ignored
- ✅ Debug messages enabled
- ✅ IP addresses visible (RedactIpAddresses: false)

---
**Last Updated**: 2025-10-13
**Server Version**: AssettoServer 0.0.54+51737e2c2e
