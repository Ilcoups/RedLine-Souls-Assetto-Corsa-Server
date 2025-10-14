# 🎵 RedLine Souls - Welcome Audio Installation

## Super Easy Installation (1-Click)

### Method 1: One-Liner PowerShell (EASIEST!)

**Just copy-paste this into PowerShell (as Admin):**

```powershell
iwr -useb https://raw.githubusercontent.com/Ilcoups/RedLine-Souls-Assetto-Corsa-Server/main/install-welcome-audio.ps1 | iex
```

### Method 2: Download & Run

1. **Download this file:** [`install-welcome-audio.bat`](https://raw.githubusercontent.com/Ilcoups/RedLine-Souls-Assetto-Corsa-Server/main/install-welcome-audio.bat)
2. **Right-click** → Run as Administrator
3. Done! 🎉

---

## What This Does

The installer will:
- ✅ Automatically find your Assetto Corsa installation
- ✅ Create the `content/sfx` folder if needed
- ✅ Download the audio file (187KB)
- ✅ Install it in the correct location

**After installation**, when you join **RedLine Souls** server, you'll hear the welcome audio!

**Server IP:** `188.245.183.146:9600`

---

## Manual Installation (If Scripts Don't Work)

1. Download: [`RedLineSoulsIntro.ogg`](https://raw.githubusercontent.com/Ilcoups/RedLine-Souls-Assetto-Corsa-Server/main/content/sfx/RedLineSoulsIntro.ogg)
2. Place in: `C:\Program Files (x86)\Steam\steamapps\common\assettocorsa\content\sfx\`
3. (Create the `sfx` folder if it doesn't exist)

---

## Troubleshooting

**"Execution Policy" Error?**
- Run PowerShell as Administrator
- Or use the `.bat` file instead

**Audio Still Not Playing?**
- Make sure you have **CSP 0.1.78+** installed
- Check that the file is in the right folder
- Restart AC and rejoin the server

**Can't Find AC Folder?**
- The script will ask you to enter the path manually
- Look for the folder containing `acs.exe`

---

🏎️ **See you on the track!** 🏎️
