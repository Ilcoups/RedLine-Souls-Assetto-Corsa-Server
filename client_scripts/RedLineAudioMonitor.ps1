# RedLine Souls Audio v3.0
# Run this BEFORE joining the server
# It will detect when you're IN PITS and play audio, then close

param(
    [string]$ServerIP = "188.245.183.146"
)

$InstallDir = "$env:USERPROFILE\Documents\RedLineSouls"
$AudioFile = "$InstallDir\RedLineSoulsIntro.ogg"

# Find VLC
$VlcPath = @(
    "${env:ProgramFiles}\VideoLAN\VLC\vlc.exe",
    "${env:ProgramFiles(x86)}\VideoLAN\VLC\vlc.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

Clear-Host
Write-Host ""
Write-Host "==========================================" -ForegroundColor Red
Write-Host "   REDLINE SOULS AUDIO" -ForegroundColor Red
Write-Host "==========================================" -ForegroundColor Red
Write-Host ""

if (-not $VlcPath) {
    Write-Host "  VLC not found! Install from videolan.org" -ForegroundColor Red
    Start-Sleep -Seconds 5
    exit 1
}

if (-not (Test-Path $AudioFile)) {
    Write-Host "  Audio file not found! Run installer first." -ForegroundColor Red
    Start-Sleep -Seconds 5
    exit 1
}

Write-Host "  VLC:   OK" -ForegroundColor Green
Write-Host "  Audio: OK" -ForegroundColor Green
Write-Host ""
Write-Host "  Now join RedLine Souls server!" -ForegroundColor Cyan
Write-Host "  Audio will play when you spawn in pits." -ForegroundColor Gray
Write-Host "  This window will close automatically." -ForegroundColor Gray
Write-Host ""

# Wait for AC to start and connect
$maxWait = 180  # 3 minutes max
$waited = 0
$connected = $false

while ($waited -lt $maxWait) {
    $acProc = Get-Process -Name "acs" -ErrorAction SilentlyContinue
    $netConn = netstat -n 2>$null | Select-String $ServerIP | Select-String "ESTABLISHED"
    
    if ($acProc -and $netConn) {
        if (-not $connected) {
            Write-Host "  Connected to server! Loading..." -ForegroundColor Yellow
            $connected = $true
        }
        
        # Check if car is actually loaded by looking at AC memory usage
        # When loading: ~500MB, When in pits with car: ~1.5GB+
        $memoryMB = [math]::Round($acProc.WorkingSet64 / 1MB)
        
        if ($memoryMB -gt 1200) {
            # Memory is high = car is loaded, you're in pits!
            Write-Host "  Car loaded! ($memoryMB MB)" -ForegroundColor Green
            Write-Host ""
            Write-Host "  ========================================" -ForegroundColor Magenta
            Write-Host "   WELCOME TO REDLINE SOULS!" -ForegroundColor Magenta
            Write-Host "  ========================================" -ForegroundColor Magenta
            Write-Host ""
            
            # Small delay then play
            Start-Sleep -Seconds 2
            
            Write-Host "  Playing audio..." -ForegroundColor Cyan
            $vlcProc = Start-Process -FilePath $VlcPath -ArgumentList "--play-and-exit --intf dummy `"$AudioFile`"" -WindowStyle Hidden -PassThru
            $vlcProc | Wait-Process -Timeout 20 -ErrorAction SilentlyContinue
            
            Write-Host "  Done! Enjoy your drive!" -ForegroundColor Green
            Start-Sleep -Seconds 2
            exit 0
        }
    } else {
        if ($waited % 10 -eq 0) {
            Write-Host "  Waiting for you to join server... ($waited sec)" -ForegroundColor Gray
        }
    }
    
    Start-Sleep -Seconds 2
    $waited += 2
}

Write-Host "  Timeout - no connection detected" -ForegroundColor Yellow
Start-Sleep -Seconds 3
exit 0
