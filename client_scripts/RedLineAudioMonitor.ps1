# RedLine Souls Audio Monitor
# This script runs in background and plays audio when you join the server

param(
    [string]$AudioFile = "$env:USERPROFILE\Documents\RedLineSoulsIntro.ogg",
    [string]$ServerIP = "188.245.183.146",
    [int]$ServerPort = 9600
)

Add-Type -AssemblyName PresentationCore

$player = $null
$hasPlayed = $false
$wasConnected = $false

Write-Host "🎵 RedLine Souls Audio Monitor Started" -ForegroundColor Red
Write-Host "   Watching for connection to $ServerIP`:$ServerPort" -ForegroundColor Gray
Write-Host "   Audio file: $AudioFile" -ForegroundColor Gray
Write-Host "   Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""

function Test-ServerConnection {
    try {
        $connections = Get-NetTCPConnection -RemoteAddress $ServerIP -RemotePort $ServerPort -State Established -ErrorAction SilentlyContinue
        return ($connections -ne $null -and $connections.Count -gt 0)
    } catch {
        return $false
    }
}

function Play-Audio {
    param([string]$FilePath)
    
    try {
        if (Test-Path $FilePath) {
            Write-Host "🔊 Playing RedLine Souls intro!" -ForegroundColor Green
            
            # Use Windows Media Player COM object
            $player = New-Object -ComObject WMPlayer.OCX
            $player.URL = $FilePath
            $player.controls.play()
            
            # Wait for it to finish (max 30 seconds)
            $timeout = 30
            while ($player.playState -ne 1 -and $timeout -gt 0) {
                Start-Sleep -Milliseconds 500
                $timeout -= 0.5
            }
            
            $player.close()
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($player) | Out-Null
            return $true
        } else {
            Write-Host "❌ Audio file not found: $FilePath" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Error playing audio: $_" -ForegroundColor Red
        return $false
    }
}

# Main monitoring loop
while ($true) {
    $isConnected = Test-ServerConnection
    
    if ($isConnected -and -not $wasConnected) {
        # Just connected!
        Write-Host "$(Get-Date -Format 'HH:mm:ss') ✅ Connected to RedLine Souls!" -ForegroundColor Green
        
        if (-not $hasPlayed) {
            # Wait a moment for the game to fully load (engine sounds, etc.)
            Write-Host "   Waiting 5 seconds for game to fully load..." -ForegroundColor Gray
            Start-Sleep -Seconds 5
            
            # Check still connected
            if (Test-ServerConnection) {
                Play-Audio -FilePath $AudioFile
                $hasPlayed = $true
            }
        }
    }
    elseif (-not $isConnected -and $wasConnected) {
        # Just disconnected
        Write-Host "$(Get-Date -Format 'HH:mm:ss') 🔌 Disconnected from server" -ForegroundColor Yellow
        $hasPlayed = $false  # Reset so it plays again next time
    }
    
    $wasConnected = $isConnected
    Start-Sleep -Seconds 2
}
