# AssettoServer Management Guide

## 🚀 Quick Commands

### Start Server (Background)
```bash
cd ~/server
./start_server.sh
```

### Stop Server
```bash
cd ~/server
./stop_server.sh
```

### Check Server Status
```bash
cd ~/server
./server_status.sh
```

### View Live Logs
```bash
cd ~/server
./view_logs.sh
```
Press `Ctrl+C` to exit log viewing

---

## 📋 Useful Commands

### View Last 50 Log Lines
```bash
tail -50 ~/server/logs/log-$(date +%Y%m%d).txt
```

### Search Logs for Errors
```bash
grep -i "error\|warning\|fail" ~/server/logs/log-$(date +%Y%m%d).txt
```

### View Console Output
```bash
tail -f ~/server/logs/server_console.log
```

### Restart Server
```bash
cd ~/server
./stop_server.sh && sleep 2 && ./start_server.sh
```

---

## 🔍 Monitoring

### Check if Server is Running
```bash
ps aux | grep AssettoServer | grep -v grep
```

### See Network Connections
```bash
netstat -tulpn | grep 9600
```

### Check CPU/Memory Usage
```bash
top -p $(pgrep -f AssettoServer)
```

---

## 📁 Important Files

- **Logs:** `~/server/logs/log-YYYYMMDD.txt`
- **Console:** `~/server/logs/server_console.log`
- **Config:** `~/server/cfg/extra_cfg.yml`
- **Server Config:** `~/server/cfg/server_cfg.ini`

---

## ⚠️ Troubleshooting

### Server Won't Start
1. Check console log: `tail -100 ~/server/logs/server_console.log`
2. Check for port conflicts: `lsof -i :9600`
3. Verify config files have no errors

### Server Crashes
1. View crash log: `tail -200 ~/server/logs/log-$(date +%Y%m%d).txt`
2. Check error log folder: `ls ~/server/logs/error/`

---

## 💡 Tips

- Server runs in background, survives terminal close
- Logs are written to files, not console
- Can safely close VS Code after starting server
- Use `./view_logs.sh` to watch server activity
- Restart server after config changes

---

## 🎮 Your Server Features

✅ Dynamic AI Traffic (up to 200 cars)
✅ 4 Weather Types (Clear, Cloudy, Fog, Partly Cloudy)
✅ Real Tokyo Time (5x speed)
✅ Day/Night Cycles
✅ Future-proof configuration
✅ Enhanced logging enabled

---

Made with ❤️ for RedLine Souls Server
