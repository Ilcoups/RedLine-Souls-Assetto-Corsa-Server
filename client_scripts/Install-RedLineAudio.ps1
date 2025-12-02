#Requires -Version 5.1
# RedLine Souls Audio Installer v3.3

$AudioUrl = "https://red-line.live/audio/RedLineSoulsIntro.ogg"
$MonitorUrl = "https://raw.githubusercontent.com/Ilcoups/RedLine-Souls-Assetto-Corsa-Server/main/client_scripts/RedLineAudioMonitor.ps1"
$InstallDir = "$env:USERPROFILE\Documents\RedLineSouls"
$AudioFile = "$InstallDir\RedLineSoulsIntro.ogg"
$MonitorFile = "$InstallDir\RedLineAudio.ps1"
$StartupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\RedLineAudio.lnk"

Clear-Host
Write-Host ""
Write-Host "==========================================" -ForegroundColor Red
Write-Host "   REDLINE SOULS AUDIO INSTALLER v3.3" -ForegroundColor Red
Write-Host "==========================================" -ForegroundColor Red
Write-Host ""

# Create folder
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

# Download audio
Write-Host "  Downloading audio file..." -ForegroundColor Cyan
try {
    (New-Object System.Net.WebClient).DownloadFile($AudioUrl, $AudioFile)
    Write-Host "  Audio: OK" -ForegroundColor Green
} catch {
    Write-Host "  Failed: $_" -ForegroundColor Red
    exit 1
}

# Download script
Write-Host "  Downloading script..." -ForegroundColor Cyan
try {
    (New-Object System.Net.WebClient).DownloadFile($MonitorUrl, $MonitorFile)
    Write-Host "  Script: OK" -ForegroundColor Green
} catch {
    Write-Host "  Failed: $_" -ForegroundColor Red
    exit 1
}

# Check VLC
$VlcPath = @(
    "${env:ProgramFiles}\VideoLAN\VLC\vlc.exe",
    "${env:ProgramFiles(x86)}\VideoLAN\VLC\vlc.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($VlcPath) {
    Write-Host "  VLC: OK" -ForegroundColor Green
} else {
    Write-Host "  VLC: NOT FOUND - Install from videolan.org!" -ForegroundColor Red
    exit 1
}

# Create startup shortcut (runs hidden on Windows boot)
try {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($StartupPath)
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$MonitorFile`""
    $Shortcut.WorkingDirectory = $InstallDir
    $Shortcut.Save()
    Write-Host "  Auto-start: OK" -ForegroundColor Green
} catch {
    Write-Host "  Failed to create startup: $_" -ForegroundColor Yellow
}

# Start it now
Start-Process powershell.exe -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$MonitorFile`"" -WindowStyle Hidden

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "   INSTALLATION COMPLETE!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  FULLY AUTOMATIC - No extra steps needed!" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Just join RedLine Souls server normally." -ForegroundColor White
Write-Host "  Audio plays 40 seconds after you connect." -ForegroundColor White
Write-Host ""
Write-Host "  Works on every PC restart automatically." -ForegroundColor Gray
Write-Host ""
Read-Host "  Press Enter to close"
