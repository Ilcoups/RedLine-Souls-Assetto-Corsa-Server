# Server Accessibility Analysis - Connection Issues

## Problem
Player from Russia reports: "The server seems to be unavailable"
- Works for most players
- Likely affected by regional restrictions/censorship
- YouTube/Discord blocked in region → server connectivity might also be affected

## Possible Causes

### 1. **Government Firewall (Most Likely)**
Russia actively blocks:
- Certain UDP ports
- Foreign game server IPs
- Non-standard protocols
- Deep packet inspection blocks gaming traffic

### 2. **ISP Throttling/Blocking**
Some Russian ISPs:
- Block gaming ports (9600, 8081)
- Throttle UDP traffic
- Require VPN to reach foreign servers

### 3. **Server-Side Issues (Less Likely)**
- Server not registered to lobby properly
- Firewall blocking certain IPs
- Timeout settings too strict

## Server-Side Solutions

### ✅ What We CAN Do

#### 1. **Optimize Connection Timeouts**
```ini
CLIENT_SEND_INTERVAL_HZ = 18  # Lower = more lenient (default 20)
```
Helps with poor connections, but won't bypass firewalls.

#### 2. **Ensure Proper Lobby Registration**
```ini
REGISTER_TO_LOBBY = 1
LOBBY_DISPLAY_NAME = RedLine Souls
```
Makes server visible in in-game browser (bypasses direct IP issues).

#### 3. **Add Server to Multiple Lobbies**
- AC official lobby
- CSP lobby
- Community directories
More exposure = more connection paths.

#### 4. **Provide Alternative Connection Info**
Server info players can share:
- Direct IP: `188.245.183.146:9600`
- HTTP Port: `8081`
- Recommend VPN if in restricted region

#### 5. **Connection Troubleshooting Guide**
Create a guide for affected players:
- Use VPN (Proton, Mullvad work in Russia)
- Try direct IP connection instead of lobby
- Check if UDP port 9600 is blocked by ISP
- Disable IPv6 (can cause routing issues)

### ❌ What We CAN'T Do

#### 1. **Change Protocols**
- AC only supports UDP (can't switch to TCP)
- Can't encrypt traffic to bypass DPI
- Game protocol is hardcoded

#### 2. **Bypass Government Blocks**
- Can't circumvent state-level censorship
- Server-side changes won't help with blocked ports
- Would need VPN/proxy on player side

#### 3. **Change Server Location**
- Server is in Germany (not blocked itself)
- Moving to different country won't help
- Issue is in player's country, not ours

## Current Server Status

**Ports in use:**
- UDP 9600 (Game)
- TCP 9600 (Game)  
- TCP 8081 (HTTP)
- UDP 12000 (Plugins)

**Lobby Registration:** Should be enabled (need to verify)

**Firewall:** Open to all IPs (no regional blocks)

## Recommended Actions

### For Us (Server Admin):
1. ✅ Verify lobby registration is working
2. ✅ Check connection timeout settings are lenient
3. ✅ Create troubleshooting guide for affected players
4. ✅ Add server to community directories
5. ✅ Provide clear connection instructions (direct IP method)

### For Affected Players:
1. **Use VPN** (most reliable solution)
   - Proton VPN (works in Russia)
   - Mullvad
   - WireGuard
2. **Try Direct IP Connection**
   - Instead of server browser
   - Might bypass some filtering
3. **Check Firewall/Antivirus**
   - Allow UDP port 9600
   - Whitelist AC executable
4. **Contact ISP**
   - Ask if gaming ports are blocked
   - Request unblock if possible

## Technical Verification Needed

1. Check if server is properly registered to lobby
2. Verify no IP-based blocking in firewall
3. Check if connection timeout settings are optimal
4. Test if direct IP connection works for affected player

## Bottom Line

**Root cause:** Government/ISP blocking in player's region  
**Can we fix server-side?** Limited - mostly player-side issue  
**Best solution:** Player uses VPN  
**What we can do:** Optimize settings, provide clear connection guide

The server itself is fine - it's the player's network path that's blocked.
