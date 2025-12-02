#Requires -Version 5.1
# RedLine Souls Audio Installer v3.2

$AudioUrl = "https://red-line.live/audio/RedLineSoulsIntro.ogg"
$MonitorUrl = "https://raw.githubusercontent.com/Ilcoups/RedLine-Souls-Assetto-Corsa-Server/main/client_scripts/RedLineAudioMonitor.ps1"
$InstallDir = "$env:USERPROFILE\Documents\RedLineSouls"
$AudioFile = "$InstallDir\RedLineSoulsIntro.ogg"
$MonitorFile = "$InstallDir\PlayAudio.ps1"
$StartupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\RedLineAudioMonitor.lnk"

Clear-Host
Write-Host ""
Write-Host "==========================================" -ForegroundColor Red
Write-Host "   REDLINE SOULS AUDIO INSTALLER v3.2" -ForegroundColor Red
Write-Host "==========================================" -ForegroundColor Red
Write-Host ""

# Remove old auto-start if exists
if (Test-Path $StartupPath) {
    Remove-Item $StartupPath -Force
    Write-Host "  Removed old auto-start shortcut" -ForegroundColor Yellow
}

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
    Write-Host "  Failed to download audio: $_" -ForegroundColor Red
    exit 1
}

# Download script
Write-Host "  Downloading script..." -ForegroundColor Cyan
try {
    (New-Object System.Net.WebClient).DownloadFile($MonitorUrl, $MonitorFile)
    Write-Host "  Script: OK" -ForegroundColor Green
} catch {
    Write-Host "  Failed to download script: $_" -ForegroundColor Red
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
}

# Create desktop shortcut
$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutFile = "$desktopPath\RedLine Souls - Join Server.lnk"

try {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutFile)
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$MonitorFile`""
    $Shortcut.WorkingDirectory = $InstallDir
    $Shortcut.IconLocation = "shell32.dll,145"
    $Shortcut.Save()
    Write-Host "  Shortcut: OK" -ForegroundColor Green
} catch {
    Write-Host "  Could not create shortcut: $_" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "   INSTALLATION COMPLETE!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  HOW TO USE:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Double-click 'RedLine Souls - Join Server' on Desktop" -ForegroundColor White
Write-Host "  2. Join server in Content Manager" -ForegroundColor White
Write-Host "  3. Audio plays when you spawn in pits" -ForegroundColor White
Write-Host ""
Write-Host "  The shortcut waits for your connection, then plays audio." -ForegroundColor Gray
Write-Host ""
Read-Host "  Press Enter to close"
