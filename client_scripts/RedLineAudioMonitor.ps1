# RedLine Souls Audio Monitor v2.2
# Plays audio when you connect to the server

param(
    [string]$ServerIP = "188.245.183.146",
    [int]$ServerPort = 9600
)

$InstallDir = "$env:USERPROFILE\Documents\RedLineSouls"
$AudioFile = "$InstallDir\RedLineSoulsIntro.ogg"

Clear-Host
Write-Host ""
Write-Host "==========================================" -ForegroundColor Red
Write-Host "   RedLine Souls Audio Monitor v2.2" -ForegroundColor Red  
Write-Host "==========================================" -ForegroundColor Red
Write-Host ""
Write-Host "  Server: $ServerIP" -ForegroundColor Gray
Write-Host "  Port:   $ServerPort" -ForegroundColor Gray
Write-Host "  Audio:  $AudioFile" -ForegroundColor Gray
Write-Host ""

# Check audio file
if (Test-Path $AudioFile) {
    Write-Host "  [OK] Audio file exists" -ForegroundColor Green
} else {
    Write-Host "  [X] Audio file NOT FOUND!" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Reinstall with:" -ForegroundColor Yellow
    Write-Host '  irm https://raw.githubusercontent.com/Ilcoups/RedLine-Souls-Assetto-Corsa-Server/main/client_scripts/Install-RedLineAudio.ps1 | iex' -ForegroundColor Cyan
    Read-Host "Press Enter to exit"
    exit 1
}

# Test audio playback now
Write-Host ""
Write-Host "  Testing audio playback..." -ForegroundColor Cyan
try {
    Add-Type -AssemblyName presentationCore
    $testPlayer = New-Object System.Windows.Media.MediaPlayer
    $testPlayer.Open([Uri]$AudioFile)
    Start-Sleep -Milliseconds 500
    if ($testPlayer.HasAudio) {
        Write-Host "  [OK] Audio can be played" -ForegroundColor Green
    } else {
        Write-Host "  [?] Audio loaded but HasAudio=false (might still work)" -ForegroundColor Yellow
    }
    $testPlayer.Close()
} catch {
    Write-Host "  [X] Audio test failed: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Waiting for you to join the server..." -ForegroundColor Cyan
Write-Host "  (Keep this window open while playing)" -ForegroundColor Gray
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$hasPlayed = $false
$wasConnected = $false
$checkCount = 0

while ($true) {
    $checkCount++
    
    # Check for connection using netstat
    $connected = $false
    try {
        $netstatOutput = netstat -n 2>$null
        if ($netstatOutput -match "$ServerIP" -and $netstatOutput -match "ESTABLISHED") {
            # More specific check
            foreach ($line in $netstatOutput) {
                if ($line -match $ServerIP -and $line -match "ESTABLISHED") {
                    $connected = $true
                    break
                }
            }
        }
    } catch {
        # Silently continue
    }
    
    # Show periodic status (every 30 seconds)
    if ($checkCount % 15 -eq 0) {
        if ($connected) {
            Write-Host "$(Get-Date -Format 'HH:mm:ss') Still connected..." -ForegroundColor Green
        } else {
            Write-Host "$(Get-Date -Format 'HH:mm:ss') Waiting for connection... (join the server!)" -ForegroundColor Gray
        }
    }
    
    # Connection state change detection
    if ($connected -and -not $wasConnected) {
        Write-Host ""
        Write-Host "$(Get-Date -Format 'HH:mm:ss') === CONNECTED TO SERVER! ===" -ForegroundColor Green
        
        if (-not $hasPlayed) {
            Write-Host "$(Get-Date -Format 'HH:mm:ss') Waiting 6 seconds for game to fully load..." -ForegroundColor Yellow
            Start-Sleep -Seconds 6
            
            Write-Host "$(Get-Date -Format 'HH:mm:ss') Playing RedLine Souls intro..." -ForegroundColor Magenta
            
            try {
                Add-Type -AssemblyName presentationCore
                $player = New-Object System.Windows.Media.MediaPlayer
                $player.Volume = 1.0
                $player.Open([Uri]$AudioFile)
                Start-Sleep -Milliseconds 300
                $player.Play()
                
                Write-Host "$(Get-Date -Format 'HH:mm:ss') Audio playing!" -ForegroundColor Green
                
                # Wait for playback
                Start-Sleep -Seconds 10
                
                $player.Stop()
                $player.Close()
                $hasPlayed = $true
                Write-Host "$(Get-Date -Format 'HH:mm:ss') Done!" -ForegroundColor Green
            } catch {
                Write-Host "$(Get-Date -Format 'HH:mm:ss') Error playing audio: $_" -ForegroundColor Red
                # Fallback: open with default app
                Write-Host "$(Get-Date -Format 'HH:mm:ss') Trying fallback (default player)..." -ForegroundColor Yellow
                try {
                    Start-Process $AudioFile
                    $hasPlayed = $true
                } catch {
                    Write-Host "$(Get-Date -Format 'HH:mm:ss') Fallback also failed: $_" -ForegroundColor Red
                }
            }
        }
        Write-Host ""
    }
    
    if (-not $connected -and $wasConnected) {
        Write-Host "$(Get-Date -Format 'HH:mm:ss') Disconnected from server" -ForegroundColor Yellow
        $hasPlayed = $false
        Write-Host ""
    }
    
    $wasConnected = $connected
    Start-Sleep -Seconds 2
}
