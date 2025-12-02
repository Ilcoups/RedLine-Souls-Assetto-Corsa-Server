#Requires -Version 5.1
# RedLine Souls Audio Monitor v3.2 - Process detection

$AudioFile = "$env:USERPROFILE\Documents\RedLineSouls\RedLineSoulsIntro.ogg"

Clear-Host
Write-Host ""
Write-Host "==========================================" -ForegroundColor Red
Write-Host "   REDLINE SOULS AUDIO v3.2" -ForegroundColor Red
Write-Host "==========================================" -ForegroundColor Red
Write-Host ""
Write-Host "  Waiting for Assetto Corsa to start..." -ForegroundColor Cyan
Write-Host "  (Press Ctrl+C to cancel)" -ForegroundColor Gray
Write-Host ""

# Find VLC
$VlcPath = @(
    "${env:ProgramFiles}\VideoLAN\VLC\vlc.exe",
    "${env:ProgramFiles(x86)}\VideoLAN\VLC\vlc.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $VlcPath) {
    Write-Host "  ERROR: VLC not found!" -ForegroundColor Red
    Read-Host "  Press Enter to exit"
    exit 1
}

if (-not (Test-Path $AudioFile)) {
    Write-Host "  ERROR: Audio file not found!" -ForegroundColor Red
    Read-Host "  Press Enter to exit"
    exit 1
}

# Wait for acs.exe (the actual game process)
$found = $false
$timeout = 300  # 5 minutes

for ($i = 0; $i -lt $timeout; $i++) {
    $acProcess = Get-Process -Name "acs" -ErrorAction SilentlyContinue
    if ($acProcess) {
        $found = $true
        break
    }
    Start-Sleep -Seconds 1
}

if (-not $found) {
    Write-Host "  Timeout - Assetto Corsa not detected" -ForegroundColor Yellow
    exit 0
}

Write-Host "  Assetto Corsa started! Waiting 40 seconds..." -ForegroundColor Green
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

Start-Sleep -Seconds 12
Write-Host "  Done! Enjoy your drive." -ForegroundColor Green
Start-Sleep -Seconds 2
