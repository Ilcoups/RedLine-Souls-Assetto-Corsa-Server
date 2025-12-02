# RedLine Souls Audio Monitor
# This script runs in background and plays audio when you join the server

param(
    [string]$ServerIP = "188.245.183.146",
    [int]$ServerPort = 9600
)

# Fixed path - matches where installer puts the file
$InstallDir = "$env:USERPROFILE\Documents\RedLineSouls"
$AudioFile = "$InstallDir\RedLineSoulsIntro.ogg"

$hasPlayed = $false
$wasConnected = $false

Write-Host ""
Write-Host "==========================================" -ForegroundColor Red
Write-Host "   RedLine Souls Audio Monitor v2.1" -ForegroundColor Red  
Write-Host "==========================================" -ForegroundColor Red
Write-Host ""
Write-Host "  Server: $ServerIP`:$ServerPort" -ForegroundColor Gray
Write-Host "  Audio:  $AudioFile" -ForegroundColor Gray
Write-Host ""

# Check if audio file exists
if (-not (Test-Path $AudioFile)) {
    Write-Host "  ERROR: Audio file not found!" -ForegroundColor Red
    Write-Host "  Run the installer again:" -ForegroundColor Yellow
    Write-Host "  irm https://raw.githubusercontent.com/Ilcoups/RedLine-Souls-Assetto-Corsa-Server/main/client_scripts/Install-RedLineAudio.ps1 | iex" -ForegroundColor Cyan
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "  [OK] Audio file found" -ForegroundColor Green

function Test-ServerConnection {
    # Method 1: Try netstat (works without admin)
    try {
        $netstat = netstat -n | Select-String "${ServerIP}:${ServerPort}.*ESTABLISHED"
        if ($netstat) { return $true }
    } catch { }
    
    # Method 2: Try Get-NetTCPConnection (may need admin)
    try {
        $connections = Get-NetTCPConnection -RemoteAddress $ServerIP -RemotePort $ServerPort -State Established -ErrorAction SilentlyContinue
        if ($connections) { return $true }
    } catch { }
    
    return $false
}

function Play-Audio {
    param([string]$FilePath)
    
    Write-Host "  Playing audio..." -ForegroundColor Green
    
    # Method 1: Use SoundPlayer for WAV or Media.SoundPlayer
    # Method 2: Use Start-Process with default player
    # Method 3: Use PowerShell MediaPlayer
    
    try {
        # Best method: Use .NET MediaPlayer (supports many formats via Windows codecs)
        Add-Type -AssemblyName presentationCore
        $mediaPlayer = New-Object System.Windows.Media.MediaPlayer
        $mediaPlayer.Open([Uri]$FilePath)
        $mediaPlayer.Volume = 0.8
        $mediaPlayer.Play()
        
        # Wait for playback to start
        Start-Sleep -Milliseconds 500
        
        # Wait for it to finish (check duration, max 30 sec)
        $waited = 0
        while ($mediaPlayer.Position -lt $mediaPlayer.NaturalDuration.TimeSpan -and $waited -lt 30) {
            Start-Sleep -Milliseconds 500
            $waited += 0.5
            # If duration is unknown, just wait a bit and exit
            if (-not $mediaPlayer.NaturalDuration.HasTimeSpan) {
                Start-Sleep -Seconds 5
                break
            }
        }
        
        $mediaPlayer.Stop()
        $mediaPlayer.Close()
        Write-Host "  [OK] Audio played!" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  MediaPlayer failed: $_" -ForegroundColor Yellow
    }
    
    # Fallback: Just open with default player
    try {
        Write-Host "  Trying default player..." -ForegroundColor Yellow
        Start-Process $FilePath
        return $true
    } catch {
        Write-Host "  ERROR: Could not play audio: $_" -ForegroundColor Red
        return $false
    }
}

# Main monitoring loop
Write-Host ""
Write-Host "  Monitoring for connection..." -ForegroundColor Cyan
Write-Host "  (Press Ctrl+C to stop)" -ForegroundColor Gray
Write-Host ""

while ($true) {
    $isConnected = Test-ServerConnection
    
    if ($isConnected) {
        if (-not $wasConnected) {
            # Just connected!
            Write-Host "$(Get-Date -Format 'HH:mm:ss') CONNECTED to RedLine Souls!" -ForegroundColor Green
        }
        
        if (-not $hasPlayed) {
            # Wait for game to fully load
            Write-Host "$(Get-Date -Format 'HH:mm:ss') Waiting 5 seconds for game to load..." -ForegroundColor Gray
            Start-Sleep -Seconds 5
            
            # Check still connected
            if (Test-ServerConnection) {
                Play-Audio -FilePath $AudioFile
                $hasPlayed = $true
            }
        }
        $wasConnected = $true
    }
    else {
        if ($wasConnected) {
            # Just disconnected
            Write-Host "$(Get-Date -Format 'HH:mm:ss') Disconnected from server" -ForegroundColor Yellow
            $hasPlayed = $false  # Reset so it plays again next time
        }
        $wasConnected = $false
    }
    
    Start-Sleep -Seconds 2
}
