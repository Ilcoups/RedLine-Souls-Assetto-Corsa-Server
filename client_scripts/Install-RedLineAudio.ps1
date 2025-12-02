#Requires -Version 5.1
<#
.SYNOPSIS
    RedLine Souls - Spawn Audio Installer v2.0
    Plays audio when you join the RedLine Souls server!

.DESCRIPTION
    This script:
    1. Downloads the RedLine Souls intro audio
    2. Creates a background monitor that detects when you join the server
    3. Plays the audio automatically when you connect!

.EXAMPLE
    irm https://raw.githubusercontent.com/Ilcoups/RedLine-Souls-Assetto-Corsa-Server/main/client_scripts/Install-RedLineAudio.ps1 | iex
#>

$ErrorActionPreference = "Stop"

# ============================================================
# Configuration
# ============================================================
$ScriptVersion = "2.0.0"
$AudioUrl = "https://red-line.live/audio/RedLineSoulsIntro.ogg"
$MonitorScriptUrl = "https://raw.githubusercontent.com/Ilcoups/RedLine-Souls-Assetto-Corsa-Server/main/client_scripts/RedLineAudioMonitor.ps1"
$InstallDir = "$env:USERPROFILE\Documents\RedLineSouls"
$AudioFile = "$InstallDir\RedLineSoulsIntro.ogg"
$MonitorScript = "$InstallDir\RedLineAudioMonitor.ps1"
$ShortcutPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\RedLineAudioMonitor.lnk"

# ============================================================
# Banner
# ============================================================
$banner = @"

    ╔══════════════════════════════════════════════════════════╗
    ║                                                          ║
    ║   ██████╗ ███████╗██████╗ ██╗     ██╗███╗   ██╗███████╗  ║
    ║   ██╔══██╗██╔════╝██╔══██╗██║     ██║████╗  ██║██╔════╝  ║
    ║   ██████╔╝█████╗  ██║  ██║██║     ██║██╔██╗ ██║█████╗    ║
    ║   ██╔══██╗██╔══╝  ██║  ██║██║     ██║██║╚██╗██║██╔══╝    ║
    ║   ██║  ██║███████╗██████╔╝███████╗██║██║ ╚████║███████╗  ║
    ║   ╚═╝  ╚═╝╚══════╝╚═════╝ ╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝  ║
    ║                     SOULS                                 ║
    ║                                                          ║
    ║         🎵 Spawn Audio Installer v$ScriptVersion               ║
    ║                                                          ║
    ╚══════════════════════════════════════════════════════════╝

"@
Write-Host $banner -ForegroundColor Red

Write-Host "  Installing RedLine Souls Audio System..." -ForegroundColor Yellow
Write-Host ""

# ============================================================
# Step 1: Create install directory
# ============================================================
Write-Host "  [1/4] Creating install directory..." -ForegroundColor Cyan
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}
Write-Host "        ✓ $InstallDir" -ForegroundColor Green

# ============================================================
# Step 2: Download audio file
# ============================================================
Write-Host "  [2/4] Downloading audio file..." -ForegroundColor Cyan
try {
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($AudioUrl, $AudioFile)
    $fileSize = (Get-Item $AudioFile).Length / 1KB
    Write-Host "        ✓ Downloaded ($([math]::Round($fileSize, 1)) KB)" -ForegroundColor Green
} catch {
    Write-Host "        ✗ Failed to download audio: $_" -ForegroundColor Red
    exit 1
}

# ============================================================
# Step 3: Download monitor script
# ============================================================
Write-Host "  [3/4] Downloading monitor script..." -ForegroundColor Cyan
try {
    $webClient.DownloadFile($MonitorScriptUrl, $MonitorScript)
    Write-Host "        ✓ Monitor script installed" -ForegroundColor Green
} catch {
    Write-Host "        ✗ Failed to download monitor: $_" -ForegroundColor Red
    exit 1
}

# ============================================================
# Step 4: Ask about auto-start
# ============================================================
Write-Host "  [4/4] Setup options..." -ForegroundColor Cyan
Write-Host ""
Write-Host "  Would you like the audio monitor to start automatically with Windows?" -ForegroundColor Yellow
Write-Host "  (It runs silently in the background and plays audio when you join the server)" -ForegroundColor Gray
Write-Host ""
$autoStart = Read-Host "  Auto-start on Windows login? (Y/n)"

if ($autoStart -notmatch '^[Nn]') {
    # Create startup shortcut
    try {
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$MonitorScript`""
        $Shortcut.WorkingDirectory = $InstallDir
        $Shortcut.Description = "RedLine Souls Audio Monitor"
        $Shortcut.Save()
        Write-Host "        ✓ Auto-start enabled" -ForegroundColor Green
    } catch {
        Write-Host "        ✗ Could not create startup shortcut: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "        ○ Auto-start skipped" -ForegroundColor Gray
}

# ============================================================
# Done!
# ============================================================
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║                                                          ║" -ForegroundColor Green
Write-Host "  ║   ✅ INSTALLATION COMPLETE!                              ║" -ForegroundColor Green
Write-Host "  ║                                                          ║" -ForegroundColor Green
Write-Host "  ║   Files installed to:                                    ║" -ForegroundColor Green
Write-Host "  ║   $InstallDir" -ForegroundColor Green
Write-Host "  ║                                                          ║" -ForegroundColor Green
Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

# ============================================================
# Start the monitor now?
# ============================================================
Write-Host "  Would you like to start the audio monitor now?" -ForegroundColor Yellow
$startNow = Read-Host "  Start now? (Y/n)"

if ($startNow -notmatch '^[Nn]') {
    Write-Host ""
    Write-Host "  Starting RedLine Souls Audio Monitor..." -ForegroundColor Cyan
    Write-Host "  (A new window will open - minimize it and play!)" -ForegroundColor Gray
    Write-Host ""
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$MonitorScript`""
}

Write-Host ""
Write-Host "  📖 Manual start command:" -ForegroundColor Yellow
Write-Host "     powershell -File `"$MonitorScript`"" -ForegroundColor Gray
Write-Host ""
Write-Host "  🎮 Now join RedLine Souls server and enjoy the intro! 🎵" -ForegroundColor Cyan
Write-Host ""
