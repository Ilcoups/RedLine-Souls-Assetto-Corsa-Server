# RedLine Souls Audio Monitor v2.3
# Plays audio when you connect to the server WITH ASSETTO CORSA RUNNING

param(
    [string]$ServerIP = "188.245.183.146"
)

$InstallDir = "$env:USERPROFILE\Documents\RedLineSouls"
$AudioFile = "$InstallDir\RedLineSoulsIntro.ogg"

Clear-Host
Write-Host ""
Write-Host "==========================================" -ForegroundColor Red
Write-Host "   RedLine Souls Audio Monitor v2.3" -ForegroundColor Red  
Write-Host "==========================================" -ForegroundColor Red
Write-Host ""
Write-Host "  Server: $ServerIP" -ForegroundColor Gray
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

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Waiting for Assetto Corsa + Server..." -ForegroundColor Cyan
Write-Host "  (Keep this window open while playing)" -ForegroundColor Gray
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$hasPlayed = $false
$wasInGame = $false
$checkCount = 0

function Is-ACRunning {
    # Check if Assetto Corsa game process is running
    $acProcess = Get-Process -Name "acs" -ErrorAction SilentlyContinue
    return ($null -ne $acProcess)
}

function Is-ConnectedToServer {
    param([string]$IP)
    try {
        $netstat = netstat -n 2>$null | Where-Object { $_ -match $IP -and $_ -match "ESTABLISHED" }
        return ($null -ne $netstat -and $netstat.Count -gt 0)
    } catch {
        return $false
    }
}

function Play-AudioFile {
    param([string]$FilePath)
    
    Write-Host "$(Get-Date -Format 'HH:mm:ss') Playing audio..." -ForegroundColor Magenta
    
    # Method 1: Try Windows Media Player COM (works with most formats if codecs installed)
    try {
        $wmp = New-Object -ComObject WMPlayer.OCX
        $wmp.settings.volume = 80
        $wmp.URL = $FilePath
        $wmp.controls.play()
        
        # Wait for it to start
        Start-Sleep -Seconds 1
        
        # Wait while playing (max 15 seconds)
        $waited = 0
        while ($wmp.playState -eq 3 -and $waited -lt 15) {
            Start-Sleep -Milliseconds 500
            $waited += 0.5
        }
        
        $wmp.controls.stop()
        $wmp.close()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($wmp) | Out-Null
        Write-Host "$(Get-Date -Format 'HH:mm:ss') Audio finished!" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "$(Get-Date -Format 'HH:mm:ss') WMP failed: $_" -ForegroundColor Yellow
    }
    
    # Method 2: Open with default application
    try {
        Write-Host "$(Get-Date -Format 'HH:mm:ss') Opening with default player..." -ForegroundColor Yellow
        Start-Process -FilePath $FilePath
        Start-Sleep -Seconds 10
        return $true
    } catch {
        Write-Host "$(Get-Date -Format 'HH:mm:ss') Default player failed: $_" -ForegroundColor Red
    }
    
    return $false
}

while ($true) {
    $checkCount++
    
    $acRunning = Is-ACRunning
    $serverConnected = Is-ConnectedToServer -IP $ServerIP
    
    # We consider "in game on server" when BOTH AC is running AND connected to server
    $inGame = $acRunning -and $serverConnected
    
    # Show status every 30 seconds
    if ($checkCount % 15 -eq 0) {
        $acStatus = if ($acRunning) { "Running" } else { "Not running" }
        $serverStatus = if ($serverConnected) { "Connected" } else { "Not connected" }
        Write-Host "$(Get-Date -Format 'HH:mm:ss') AC: $acStatus | Server: $serverStatus" -ForegroundColor Gray
    }
    
    # Detect joining server
    if ($inGame -and -not $wasInGame) {
        Write-Host ""
        Write-Host "$(Get-Date -Format 'HH:mm:ss') =====================================" -ForegroundColor Green
        Write-Host "$(Get-Date -Format 'HH:mm:ss')  JOINED REDLINE SOULS SERVER!" -ForegroundColor Green
        Write-Host "$(Get-Date -Format 'HH:mm:ss') =====================================" -ForegroundColor Green
        
        if (-not $hasPlayed) {
            Write-Host "$(Get-Date -Format 'HH:mm:ss') Waiting 8 seconds for game to load..." -ForegroundColor Yellow
            Start-Sleep -Seconds 8
            
            # Double check still in game
            if ((Is-ACRunning) -and (Is-ConnectedToServer -IP $ServerIP)) {
                $result = Play-AudioFile -FilePath $AudioFile
                $hasPlayed = $result
            } else {
                Write-Host "$(Get-Date -Format 'HH:mm:ss') Lost connection, skipping audio" -ForegroundColor Yellow
            }
        }
        Write-Host ""
    }
    
    # Detect leaving server
    if (-not $inGame -and $wasInGame) {
        Write-Host "$(Get-Date -Format 'HH:mm:ss') Left server or closed game" -ForegroundColor Yellow
        $hasPlayed = $false
    }
    
    $wasInGame = $inGame
    Start-Sleep -Seconds 2
}
