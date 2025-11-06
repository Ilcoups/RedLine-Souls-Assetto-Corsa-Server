# Audio Files Directory

## Required File

Copy `RedLineSoulsIntro.ogg` from your Windows PC to this directory:

**Source:** `D:\SteamLibrary\steamapps\common\assettocorsa\content\sfx\RedLineSoulsIntro.ogg`

**Destination:** `/home/acserver/server/wwwroot/audio/RedLineSoulsIntro.ogg`

This file will be served via HTTP at: `http://<server_ip>:8081/audio/RedLineSoulsIntro.ogg`

## File Transfer Methods

### Using SCP (from Windows):
```bash
scp "D:\SteamLibrary\steamapps\common\assettocorsa\content\sfx\RedLineSoulsIntro.ogg" user@server:/home/acserver/server/wwwroot/audio/
```

### Using WinSCP or FileZilla:
Upload the file to `/home/acserver/server/wwwroot/audio/`

