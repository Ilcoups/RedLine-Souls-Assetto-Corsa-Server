# AssettoServer Production Checklist ✅
## Comprehensive Setup Verification - RedLine Souls Server

**Last Checked**: October 13, 2025  
**Server Version**: AssettoServer 0.0.54+51737e2c2e  
**Server IP**: 188.245.183.146:9600

---

## 📋 CRITICAL REQUIREMENTS

### 1. Network & Connectivity
| Item | Required | Status | Notes |
|------|----------|--------|-------|
| **TCP Port 9600 Open** | ✅ Required | ⚠️ UNCHECKED | Need to verify firewall |
| **UDP Port 9600 Open** | ✅ Required | ⚠️ UNCHECKED | Need to verify firewall |
| **HTTP Port 8081 Open** | ✅ Required | ⚠️ UNCHECKED | For lobby registration |
| **Port Forwarding** | ✅ Required | ⚠️ UNCHECKED | Router/VPS config |
| **Public IP Accessible** | ✅ Required | ✅ DONE | 188.245.183.146 |
| **Lobby Registration** | ✅ Required | ✅ DONE | Shows in Content Manager |

**Priority**: 🔴 CRITICAL - If ports aren't open, players can't connect!

### 2. Core Configuration Files
| Item | Required | Status | Notes |
|------|----------|--------|-------|
| **server_cfg.ini** | ✅ Required | ✅ DONE | Core settings configured |
| **extra_cfg.yml** | ✅ Required | ✅ DONE | Advanced config complete |
| **entry_list.ini** | ✅ Required | ✅ DONE | 53 slots configured |
| **data_track_params.ini** | ⚠️ Optional | ✅ DONE | Tokyo timezone set |
| **YAML Syntax Valid** | ✅ Required | ✅ DONE | Server starts successfully |
| **Admin Password Set** | ✅ Required | ✅ DONE | F*ckTrafficJam2025!RedLine |

**Priority**: 🟢 COMPLETE

### 3. Required Content
| Item | Required | Status | Notes |
|------|----------|--------|-------|
| **Track Files** | ✅ Required | ✅ DONE | SRP Beta installed |
| **Car Data Files** | ✅ Required | ✅ DONE | 30 cars with checksums |
| **Track Physics** | ✅ Required | ✅ DONE | AI spline present |
| **Content Checksums** | ⚠️ Optional | ⚠️ DISABLED | Intentionally for compatibility |

**Priority**: 🟢 COMPLETE

---

## 🔧 RECOMMENDED SETTINGS

### 4. AI Traffic Configuration
| Item | Recommended | Status | Notes |
|------|-------------|--------|-------|
| **AiPerPlayerTargetCount** | 8-15 | ✅ DONE | Set to 12 |
| **MaxAiTargetCount** | 100-300 | ✅ DONE | Set to 200 |
| **MaxPlayerDistanceToAiSplineMeters** | 100-200 | ✅ DONE | Set to 150 |
| **SmoothCamber** | true | ✅ DONE | Enabled |
| **HourlyTrafficDensity** | Optional | ✅ DONE | Tokyo pattern |
| **Debug Overlay** | false | ✅ DONE | Hidden for players |
| **AI Speed Range** | 80-150 km/h | ✅ DONE | 80-144 km/h |

**Priority**: 🟢 COMPLETE

### 5. Weather System
| Item | Recommended | Status | Notes |
|------|-------------|--------|-------|
| **EnableWeatherFx** | true | ✅ DONE | CSP 0.1.76+ required |
| **Weather Plugin** | Any | ✅ DONE | RandomWeatherPlugin |
| **Weather Count** | 3-5 types | ✅ DONE | 3 types (no rain) |
| **Smooth Transitions** | true | ✅ DONE | WeatherFX enabled |
| **Real Time Sync** | Optional | ✅ DONE | EnableRealTime: true |

**Priority**: 🟢 COMPLETE

### 6. Time Configuration
| Item | Recommended | Status | Notes |
|------|-------------|--------|-------|
| **TIME_OF_DAY_MULT** | 1-10 | ✅ DONE | Set to 8 |
| **StartTime** | Any | ✅ DONE | 14:00 (2 PM) |
| **Timezone** | Correct | ✅ DONE | Asia/Tokyo |
| **LockServerDate** | true | ✅ DONE | Prevents time drift |

**Priority**: 🟢 COMPLETE

### 7. Network Optimization
| Item | Recommended | Status | Notes |
|------|-------------|--------|-------|
| **EnableCustomUpdate** | CSP Only | ⚠️ CHANGED | Disabled for compatibility |
| **NetworkBubbleDistance** | 500-1000 | ✅ DONE | Set to 500 |
| **MaxPing** | 300-500 | ✅ DONE | Set to 500 |
| **KickPacketLoss** | 0 | ✅ DONE | Disabled |
| **Send/Recv Buffers** | 512KB+ | ⚠️ UNCHECKED | Need to verify |

**Priority**: 🟡 CHECK BUFFERS

### 8. Connection Tolerance
| Item | Recommended | Status | Notes |
|------|-------------|--------|-------|
| **DISABLE_CHECKSUMS** | 1 (casual) | ✅ DONE | Maximum compatibility |
| **IgnoreMissingCarData** | true | ✅ DONE | Enabled |
| **IgnoreCarPhysicsMismatch** | true | ✅ DONE | Enabled |
| **PlayerLoadingTimeout** | 5-15 min | ✅ DONE | 10 minutes |
| **PlayerChecksumTimeout** | 40-120 sec | ✅ DONE | 120 seconds |

**Priority**: 🟢 COMPLETE

### 9. Session Configuration
| Item | Recommended | Status | Notes |
|------|-------------|--------|-------|
| **PICKUP_MODE_ENABLED** | 1 | ✅ DONE | Free join |
| **LOOP_MODE** | 1 | ✅ DONE | 24h practice |
| **Session Duration** | 1440 min | ✅ DONE | 24 hours |
| **LOCKED_ENTRY_LIST** | 0 | ✅ DONE | Open slots |
| **MaxPlayerCount** | 30-50 | ✅ DONE | Set to 40 |

**Priority**: 🟢 COMPLETE

---

## 🛡️ SECURITY & ADMINISTRATION

### 10. Admin Configuration
| Item | Recommended | Status | Notes |
|------|-------------|--------|-------|
| **Admin Password** | Strong | ✅ DONE | Complex password set |
| **admins.txt Created** | Yes | ⚠️ UNCHECKED | Need to verify file exists |
| **Steam IDs Added** | Yes | ⚠️ UNCHECKED | Need your Steam ID |
| **RCON Port** | 0 (disabled) | ✅ DONE | Disabled for security |
| **Whitelist** | Optional | ❌ NOT USED | Public server |

**Priority**: 🟡 ADD YOUR STEAM ID

### 11. Anti-Cheat & Protection
| Item | Recommended | Status | Notes |
|------|-------------|--------|-------|
| **UseSteamAuth** | Optional | ❌ DISABLED | Requires CSP 0.1.75+ |
| **MandatoryClientSecurityLevel** | 0-1 | ✅ DONE | Set to 0 (casual) |
| **ValidateDlcOwnership** | Optional | ❌ NOT USED | Empty list |
| **EnableAntiAfk** | true | ✅ DONE | 10 minute timeout |

**Priority**: 🟢 COMPLETE (appropriate for casual server)

---

## 📊 MONITORING & LOGGING

### 12. Logging System
| Item | Recommended | Status | Notes |
|------|-------------|--------|-------|
| **Log Level** | Debug/Verbose | ✅ DONE | Set to Verbose |
| **appsettings.json** | Created | ✅ DONE | Comprehensive logging |
| **Log Rotation** | 7-30 days | ✅ DONE | 7 days retention |
| **Console Logging** | Enabled | ✅ DONE | Dual output |
| **Network Logging** | Verbose | ✅ DONE | Full connection tracking |
| **RedactIpAddresses** | false (debug) | ✅ DONE | IPs visible |

**Priority**: 🟢 COMPLETE

### 13. Monitoring Tools
| Item | Recommended | Status | Notes |
|------|-------------|--------|-------|
| **Connection Monitor Script** | Yes | ✅ DONE | monitor_connections.sh |
| **Management Scripts** | Yes | ✅ DONE | start/stop/status |
| **Log Analysis** | Yes | ✅ DONE | Multiple guides created |
| **Error Tracking** | Yes | ✅ DONE | Grep scripts ready |

**Priority**: 🟢 COMPLETE

---

## 🎮 CLIENT COMPATIBILITY

### 14. CSP Requirements
| Item | Recommended | Status | Notes |
|------|-------------|--------|-------|
| **Minimum CSP Version** | Document | ✅ DONE | 0.1.76+ required |
| **EnableWeatherFx** | true | ✅ DONE | Requires 0.1.76+ |
| **EnableCustomUpdate** | Optional | ⚠️ DISABLED | For max compatibility |
| **EnableClientMessages** | Optional | ❌ DISABLED | Requires 0.1.77+ |
| **CSP Feature List** | Documented | ✅ DONE | Logged per connection |

**Priority**: 🟢 COMPLETE

### 15. Content Manager Integration
| Item | Recommended | Status | Notes |
|------|-------------|--------|-------|
| **EnableServerDetails** | true | ✅ DONE | Shows description |
| **ServerDescription** | Set | ✅ DONE | With Discord link |
| **LoadingImageUrl** | Optional | ❌ NOT SET | Could add custom image |
| **Server Preview** | Optional | ❌ NOT SET | Could add server image |

**Priority**: 🟡 COULD ADD IMAGES

---

## 🔍 ISSUES TO CHECK

### 🔴 CRITICAL - MUST VERIFY IMMEDIATELY

1. **Port Forwarding** ⚠️
   ```bash
   # Check if ports are actually open from external network
   # From another computer/network, test:
   telnet 188.245.183.146 9600
   ```
   **Action Required**: Test ports with online port checker

2. **Firewall Rules** ⚠️
   ```bash
   # Check if UFW/iptables blocking ports
   sudo ufw status
   sudo iptables -L -n | grep 9600
   ```
   **Action Required**: Verify firewall allows TCP/UDP 9600 and TCP 8081

3. **Network Buffers** ⚠️
   ```bash
   # Check current buffer sizes in server_cfg.ini
   grep "BUFFER" cfg/server_cfg.ini
   ```
   **Action Required**: Verify SEND_BUFFER_SIZE and RECV_BUFFER_SIZE set to 524288

### 🟡 IMPORTANT - SHOULD CHECK SOON

4. **Admin Steam ID** ⚠️
   ```bash
   # Check if your Steam ID is in admins.txt
   cat admins.txt
   ```
   **Action Required**: Add your Steam ID (76561199185532445?) to admins.txt

5. **Management Scripts Executable** ⚠️
   ```bash
   # Verify all scripts are executable
   ls -l *.sh
   ```
   **Action Required**: chmod +x *.sh if not already done

6. **Server Auto-Start** ⚠️
   ```bash
   # Check if server starts on system boot
   crontab -l | grep AssettoServer
   ```
   **Action Required**: Consider adding @reboot cron job

### 🟢 OPTIONAL - NICE TO HAVE

7. **Loading Screen Image** 
   - Could add custom image URL to LoadingImageUrl
   - Requires CSP 0.1.80+

8. **Server Preview Image**
   - Add preview image in Content Manager
   - Shows in server browser

9. **Discord Integration**
   - DiscordAuditPlugin already available
   - Could configure webhook for player join/leave notifications

10. **Backup System**
    - Automated config backups
    - Log archiving
    - Git commits (already doing this!)

---

## ✅ SUMMARY

### What's Working Great ✅
- Server starts and runs stable
- Lobby registration successful
- AI traffic spawning correctly
- Weather system cycling properly
- Players can connect (confirmed: VersusGame, il)
- Comprehensive logging active
- Configuration well documented
- Git repository maintained

### What Needs Immediate Attention 🔴
1. **Verify port forwarding** - Critical for external connections
2. **Check firewall rules** - Make sure TCP/UDP 9600 + TCP 8081 open
3. **Confirm network buffers** - Should be 524288 for both

### What Should Be Done Soon 🟡
4. **Add admin Steam ID to admins.txt**
5. **Verify all management scripts are executable**
6. **Consider auto-start on reboot**

### Optional Improvements 🟢
7. Custom loading screen image
8. Discord webhook notifications
9. Automated backups (beyond git)

---

## 🔧 VERIFICATION COMMANDS

Run these to check your server health:

```bash
# 1. Check ports are listening
sudo netstat -tulpn | grep -E "9600|8081"

# 2. Check firewall status
sudo ufw status verbose

# 3. Check if server is running
ps aux | grep AssettoServer | grep -v grep

# 4. Check recent connections
grep "attempting to connect" /home/acserver/server/logs/log-$(date +%Y%m%d).txt | tail -10

# 5. Check for errors
grep -E "ERR|WRN|Exception" /home/acserver/server/logs/log-$(date +%Y%m%d).txt | tail -20

# 6. Check network buffer sizes
grep "BUFFER" /home/acserver/server/cfg/server_cfg.ini

# 7. Verify admin file exists
ls -la /home/acserver/server/admins.txt

# 8. Check script permissions
ls -l /home/acserver/server/*.sh
```

---

## 📚 REFERENCES

- [AssettoServer Official Docs](https://assettoserver.org/)
- [CSP Version Requirements](https://github.com/ac-custom-shaders-patch/acc-extension-config)
- [Your README.md](README.md)
- [Disconnect Tracking Guide](DISCONNECT_TRACKING.md)
- [Future Proofing Guide](FUTURE_PROOFING_GUIDE.md)

---

**Next Steps**: 
1. Run the verification commands above
2. Fix any critical issues found
3. Test external connectivity with port checker
4. Add your Steam ID to admins.txt

**Created**: October 13, 2025  
**For**: RedLine Souls AC Server
