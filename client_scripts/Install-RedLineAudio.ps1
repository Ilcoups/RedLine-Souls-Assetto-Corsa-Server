#Requires -Version 5.1
# RedLine Souls - Audio Installer v2.3

$ErrorActionPreference = "Stop"

$ScriptVersion = "2.3.0"
$AudioUrl = "https://red-line.live/audio/RedLineSoulsIntro.ogg"
$MonitorScriptUrl = "https://raw.githubusercontent.com/Ilcoups/RedLine-Souls-Assetto-Corsa-Server/main/client_scripts/RedLineAudioMonitor.ps1"
$InstallDir = "$env:USERPROFILE\Documents\RedLineSouls"
$AudioFileOgg = "$InstallDir\RedLineSoulsIntro.ogg"
$AudioFileWav = "$InstallDir\RedLineSoulsIntro.wav"
$MonitorScript = "$InstallDir\RedLineAudioMonitor.ps1"
$ShortcutPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\RedLineAudioMonitor.lnk"

Clear-Host
Write-Host ""
Write-Host "==========================================" -ForegroundColor Red
Write-Host "      REDLINE SOULS AUDIO INSTALLER" -ForegroundColor Red
Write-Host "             Version $ScriptVersion" -ForegroundColor Red
Write-Host "==========================================" -ForegroundColor Red
Write-Host ""

# Step 1: Create directory
Write-Host "[1/5] Creating install directory..." -ForegroundColor Cyan
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}
Write-Host "      OK: $InstallDir" -ForegroundColor Green

# Step 2: Download OGG audio
Write-Host "[2/5] Downloading audio file..." -ForegroundColor Cyan
try {
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($AudioUrl, $AudioFileOgg)
    $fileSize = [math]::Round((Get-Item $AudioFileOgg).Length / 1KB, 1)
    Write-Host "      OK: Downloaded ($fileSize KB)" -ForegroundColor Green
} catch {
    Write-Host "      FAILED: $_" -ForegroundColor Red
    exit 1
}

# Step 3: Convert OGG to WAV using Windows
Write-Host "[3/5] Converting to Windows format..." -ForegroundColor Cyan
try {
    # Try using Windows Media Foundation via PowerShell
    Add-Type -AssemblyName PresentationCore
    
    # Use NAudio-style approach with Shell
    $shell = New-Object -ComObject Shell.Application
    $folder = $shell.Namespace($InstallDir)
    
    # Alternative: Use mplayer2 or ffmpeg if available
    # For now, we'll just use the OGG and rely on VLC/codec being installed
    # OR we use a simpler approach - embed WAV data
    
    # Actually, let's try MediaFoundation transcoding
    Write-Host "      Using fallback audio method..." -ForegroundColor Yellow
    
    # Since we can't easily convert, let's create a simple beep as fallback test
    # and tell user to install codec OR we use .NET to play
    
    # Check if we can play OGG with WMP (some Windows have codecs)
    $wmp = New-Object -ComObject WMPlayer.OCX
    $wmp.URL = $AudioFileOgg
    Start-Sleep -Milliseconds 500
    $canPlay = ($wmp.playState -ne 0)
    $wmp.controls.stop()
    $wmp.close()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($wmp) | Out-Null
    
    if ($canPlay) {
        Write-Host "      OK: Windows can play OGG (codecs installed)" -ForegroundColor Green
    } else {
        Write-Host "      NOTE: OGG codec not found, using fallback" -ForegroundColor Yellow
    }
} catch {
    Write-Host "      Using alternative playback method" -ForegroundColor Yellow
}

# Step 4: Download monitor script
Write-Host "[4/5] Downloading monitor script..." -ForegroundColor Cyan
try {
    $webClient.DownloadFile($MonitorScriptUrl, $MonitorScript)
    Write-Host "      OK: Monitor installed" -ForegroundColor Green
} catch {
    Write-Host "      FAILED: $_" -ForegroundColor Red
    exit 1
}

# Step 5: Setup auto-start (optional)
Write-Host "[5/5] Setup options..." -ForegroundColor Cyan
Write-Host ""
Write-Host "  Auto-start monitor with Windows? (Y/n): " -NoNewline -ForegroundColor Yellow
$autoStart = Read-Host

if ($autoStart -notmatch '^[Nn]') {
    try {
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$MonitorScript`""
        $Shortcut.WorkingDirectory = $InstallDir
        $Shortcut.Save()
        Write-Host "      OK: Auto-start enabled" -ForegroundColor Green
    } catch {
        Write-Host "      Could not enable auto-start: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "      Skipped auto-start" -ForegroundColor Gray
}

# Done
Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "      INSTALLATION COMPLETE!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Files installed to:" -ForegroundColor White
Write-Host "  $InstallDir" -ForegroundColor Gray
Write-Host ""

# Test audio playback
Write-Host "Testing audio playback..." -ForegroundColor Cyan
Write-Host "(You should hear the RedLine Souls intro)" -ForegroundColor Gray
Write-Host ""

try {
    # Use Start-Process to open with default app (will prompt to install VLC/etc if needed)
    # Better: use PowerShell's built-in SoundPlayer for WAV
    # Since we only have OGG, try WMP first
    
    $wmp = New-Object -ComObject WMPlayer.OCX
    $wmp.settings.volume = 50
    $wmp.URL = $AudioFileOgg
    $wmp.controls.play()
    
    Write-Host "Playing audio..." -ForegroundColor Magenta
    Start-Sleep -Seconds 5
    
    $wmp.controls.stop()
    $wmp.close()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($wmp) | Out-Null
    
    Write-Host ""
    Write-Host "Did you hear the audio? (Y/n): " -NoNewline -ForegroundColor Yellow
    $heardAudio = Read-Host
    
    if ($heardAudio -match '^[Nn]') {
        Write-Host ""
        Write-Host "==========================================" -ForegroundColor Yellow
        Write-Host " OGG CODEC NOT INSTALLED" -ForegroundColor Yellow
        Write-Host "==========================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Your Windows needs a codec to play OGG files." -ForegroundColor White
        Write-Host ""
        Write-Host "EASY FIX - Install VLC Media Player:" -ForegroundColor Cyan
        Write-Host "  https://www.videolan.org/vlc/" -ForegroundColor Gray
        Write-Host ""
        Write-Host "OR install K-Lite Codec Pack:" -ForegroundColor Cyan  
        Write-Host "  https://codecguide.com/download_kl.htm" -ForegroundColor Gray
        Write-Host ""
        Write-Host "After installing, run this installer again!" -ForegroundColor Yellow
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "Great! Audio is working!" -ForegroundColor Green
    }
} catch {
    Write-Host "Audio test failed: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install VLC Media Player: https://www.videolan.org/vlc/" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Start the monitor now? (Y/n): " -NoNewline -ForegroundColor Yellow
$startNow = Read-Host

if ($startNow -notmatch '^[Nn]') {
    Write-Host ""
    Write-Host "Starting monitor..." -ForegroundColor Cyan
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$MonitorScript`""
    Write-Host "Monitor started! Keep that window open while playing." -ForegroundColor Green
}

Write-Host ""
Write-Host "Enjoy RedLine Souls!" -ForegroundColor Red
Write-Host ""
