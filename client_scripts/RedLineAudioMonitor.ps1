#Requires -Version 5.1
# RedLine Souls Audio Monitor v3.1 - Simple 40 second delay

$ServerIP = "188.245.183.146"
$AudioFile = "$env:USERPROFILE\Documents\RedLineSouls\RedLineSoulsIntro.ogg"

Clear-Host
Write-Host ""
Write-Host "==========================================" -ForegroundColor Red
Write-Host "   REDLINE SOULS AUDIO v3.1" -ForegroundColor Red
Write-Host "==========================================" -ForegroundColor Red
Write-Host ""
Write-Host "  Waiting for you to join the server..." -ForegroundColor Cyan
Write-Host "  (Press Ctrl+C to cancel)" -ForegroundColor Gray
Write-Host ""

# Find VLC
$VlcPath = @(
    "${env:ProgramFiles}\VideoLAN\VLC\vlc.exe",
    "${env:ProgramFiles(x86)}\VideoLAN\VLC\vlc.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $VlcPath) {
    Write-Host "  ERROR: VLC not found!" -ForegroundColor Red
    Write-Host "  Install from videolan.org" -ForegroundColor Yellow
    Read-Host "  Press Enter to exit"
    exit 1
}

if (-not (Test-Path $AudioFile)) {
    Write-Host "  ERROR: Audio file not found!" -ForegroundColor Red
    Write-Host "  Run installer again" -ForegroundColor Yellow
    Read-Host "  Press Enter to exit"
    exit 1
}

# Wait for connection to RedLine server
$connected = $false
$timeout = 180  # 3 minutes to connect

for ($i = 0; $i -lt $timeout; $i++) {
    $connections = Get-NetTCPConnection -RemoteAddress $ServerIP -ErrorAction SilentlyContinue
    if ($connections) {
        $connected = $true
        break
    }
    Start-Sleep -Seconds 1
}

if (-not $connected) {
    Write-Host "  Timeout - no connection detected" -ForegroundColor Yellow
    exit 0
}

Write-Host "  Connected! Waiting 40 seconds to load..." -ForegroundColor Green
Write-Host ""

# Countdown
for ($i = 40; $i -gt 0; $i--) {
    Write-Host "`r  Spawning in $i seconds...  " -NoNewline -ForegroundColor Yellow
    Start-Sleep -Seconds 1
}

Write-Host "`r                                    " -NoNewline
Write-Host "`r  WELCOME TO REDLINE SOULS!" -ForegroundColor Red
Write-Host ""

# Play audio
Start-Process -FilePath $VlcPath -ArgumentList "--play-and-exit", "--intf", "dummy", "`"$AudioFile`"" -WindowStyle Hidden

# Wait for audio to finish (about 10 seconds)
Start-Sleep -Seconds 12

Write-Host "  Done! Enjoy your drive." -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 2
