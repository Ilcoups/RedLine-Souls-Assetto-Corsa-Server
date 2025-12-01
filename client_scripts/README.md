# RedLine Souls - Client Scripts

This folder contains scripts that players can install on their computers to enhance their RedLine Souls experience.

## 🎵 Spawn Audio Script

Plays the RedLine Souls theme when you join the server!

### Quick Install (Recommended)

Open **PowerShell** and run this one command:

```powershell
irm https://raw.githubusercontent.com/Ilcoups/RedLine-Souls-Assetto-Corsa-Server/main/client_scripts/Install-RedLineAudio.ps1 | iex
```

That's it! The installer will:
- ✅ Auto-detect your Assetto Corsa installation
- ✅ Download the latest script from GitHub
- ✅ Install it to the correct folder
- ✅ Work on any drive (C:, D:, etc.)

### Manual Install

If you prefer to install manually:

1. Download `redline_spawn_audio.lua`
2. Copy it to: `Documents\Assetto Corsa\cfg\lua\online\`
3. Create the `online` folder if it doesn't exist
4. Restart Assetto Corsa

### Uninstall

To remove the script, run:

```powershell
irm https://raw.githubusercontent.com/Ilcoups/RedLine-Souls-Assetto-Corsa-Server/main/client_scripts/Install-RedLineAudio.ps1 | iex -Uninstall
```

Or simply delete the file from `Documents\Assetto Corsa\cfg\lua\online\redline_spawn_audio.lua`

### Requirements

- ✅ Assetto Corsa (Steam version)
- ✅ Custom Shaders Patch (CSP) 0.1.78+
- ✅ Content Manager (recommended)

### Troubleshooting

**Audio doesn't play:**
- Make sure CSP is installed and up to date
- Check that you're connected to a RedLine Souls server
- Try restarting Assetto Corsa

**PowerShell shows red errors:**
- Right-click PowerShell and "Run as Administrator"
- If blocked by execution policy, run: `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`

**Can't find Documents folder:**
- The script handles OneDrive/cloud Documents folders automatically
- If issues persist, install manually to the folder

---

## 📁 Files in this folder

| File | Description |
|------|-------------|
| `Install-RedLineAudio.ps1` | PowerShell installer script |
| `redline_spawn_audio.lua` | The actual CSP Lua script |
| `README.md` | This file |

---

## 🔗 Links

- **Discord**: https://discord.gg/YJJEGAhf
- **Server**: RedLine Souls | Shuto Cruise | Dynamic AI Traffic

---

*Made with ❤️ by the RedLine Souls team*
