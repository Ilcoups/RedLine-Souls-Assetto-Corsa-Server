# 🎵 RedLine Souls - Welcome Audio Installation

Get the full RedLine Souls experience with our custom welcome audio!

## 🚀 Quick Install (Recommended)

**Run this one command in PowerShell:**

```powershell
iwr -useb https://raw.githubusercontent.com/Ilcoups/RedLine-Souls-Assetto-Corsa-Server/main/install-welcome-audio-complete.ps1 | iex
```

This installs:
- ✅ Audio file (`RedLineSoulsIntro.ogg`)
- ✅ Lua script (automatic playback)
- ✅ Everything you need!

Then:
1. **Restart Assetto Corsa** (if running)
2. **Join the server**: `188.245.183.146:9600`
3. **Enjoy!** Audio plays 3 seconds after joining

---

## 📋 Requirements

- **CSP 0.1.60+** (any version works with Lua script)
- **Windows** (for PowerShell installer)
- **5 seconds** of your time

---

## 🔧 Manual Installation

If you prefer to install manually:

### Step 1: Download Files
- Audio: [RedLineSoulsIntro.ogg](https://raw.githubusercontent.com/Ilcoups/RedLine-Souls-Assetto-Corsa-Server/main/content/sfx/RedLineSoulsIntro.ogg)
- Script: [redline_souls_welcome.lua](https://raw.githubusercontent.com/Ilcoups/RedLine-Souls-Assetto-Corsa-Server/main/redline_souls_welcome.lua)

### Step 2: Install Audio File
Copy `RedLineSoulsIntro.ogg` to:
```
C:\Program Files (x86)\Steam\steamapps\common\assettocorsa\content\sfx\
```
(Create `sfx` folder if it doesn't exist)

### Step 3: Install Lua Script
Copy `redline_souls_welcome.lua` to:
```
Documents\Assetto Corsa\cfg\lua\online\
```
(Create folders if they don't exist)

### Step 4: Restart & Join
- Restart Assetto Corsa
- Join server: `188.245.183.146:9600`
- Audio plays after 3 seconds!

---

## ❓ Troubleshooting

### No audio plays?
1. ✅ Check CSP is installed (any version 0.1.60+)
2. ✅ Verify audio file exists: `assettocorsa\content\sfx\RedLineSoulsIntro.ogg`
3. ✅ Verify Lua script exists: `Documents\Assetto Corsa\cfg\lua\online\redline_souls_welcome.lua`
4. ✅ Check in-game UI volume is not muted
5. ✅ Restart AC completely before testing

### Audio file not found error?
- Run the installer script again
- Or manually download and place the audio file

### Still not working?
- Check AC logs: `Documents\Assetto Corsa\logs\log.txt`
- Look for "RedLine Souls" messages
- Ask for help in Discord: https://discord.gg/YJJEGAhf

---

## 🎮 How It Works

The Lua script:
- Runs client-side (on your PC)
- Detects when you join RedLine Souls server
- Waits 3 seconds
- Plays the welcome audio
- Only plays once per session

**This is the most reliable method!** Server-side audio triggers are limited by CSP, but client-side Lua scripts work perfectly.

---

## 🔒 Is It Safe?

**Yes!** The Lua script:
- Only plays audio (no system access)
- Only runs on RedLine Souls server
- Open source (check the code yourself)
- No data collection
- No external connections

---

## 📝 For Server Admins

Want to use this for your own server?

1. Edit `redline_souls_welcome.lua`
2. Change `serverIP = "188.245.183.146"` to your IP
3. Change audio file path if needed
4. Distribute to your players!

---

## 💬 Support

- **Discord**: https://discord.gg/YJJEGAhf
- **Server**: 188.245.183.146:9600
- **GitHub**: https://github.com/Ilcoups/RedLine-Souls-Assetto-Corsa-Server

---

*Enjoy your drive on RedLine Souls! 🏁*

