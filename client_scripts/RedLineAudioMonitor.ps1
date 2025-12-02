# RedLine Souls Audio Monitor v2.4
# Plays audio using VLC when you join the server

param(
    [string]$ServerIP = "188.245.183.146"
)

$InstallDir = "$env:USERPROFILE\Documents\RedLineSouls"
$AudioFile = "$InstallDir\RedLineSoulsIntro.ogg"

# Find VLC
$VlcPaths = @(
    "${env:ProgramFiles}\VideoLAN\VLC\vlc.exe",
    "${env:ProgramFiles(x86)}\VideoLAN\VLC\vlc.exe",
    "$env:LOCALAPPDATA\Programs\VideoLAN\VLC\vlc.exe"
)

$VlcPath = $null
foreach ($path in $VlcPaths) {
    if (Test-Path $path) {
        $VlcPath = $path
        break
    }
}

Clear-Host
Write-Host ""
Write-Host "==========================================" -ForegroundColor Red
Write-Host "   RedLine Souls Audio Monitor v2.4" -ForegroundColor Red  
Write-Host "==========================================" -ForegroundColor Red
Write-Host ""
Write-Host "  Server: $ServerIP" -ForegroundColor Gray
Write-Host "  Audio:  $AudioFile" -ForegroundColor Gray

if ($VlcPath) {
    Write-Host "  VLC:    $VlcPath" -ForegroundColor Green
} else {
    Write-Host "  VLC:    NOT FOUND!" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Please install VLC from https://www.videolan.org/vlc/" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check audio file
if (-not (Test-Path $AudioFile)) {
    Write-Host ""
    Write-Host "  ERROR: Audio file not found!" -ForegroundColor Red
    Write-Host "  Run installer: irm https://raw.githubusercontent.com/Ilcoups/RedLine-Souls-Assetto-Corsa-Server/main/client_scripts/Install-RedLineAudio.ps1 | iex" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "  Audio:  File exists" -ForegroundColor Green

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Waiting for Assetto Corsa + Server..." -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$hasPlayed = $false
$wasInGame = $false
$checkCount = 0

function Is-ACRunning {
    $proc = Get-Process -Name "acs" -ErrorAction SilentlyContinue
    return ($null -ne $proc)
}

function Is-ConnectedToServer {
    param([string]$IP)
    try {
        $result = netstat -n 2>$null | Select-String $IP | Select-String "ESTABLISHED"
        return ($null -ne $result)
    } catch {
        return $false
    }
}

function Play-WithVLC {
    param([string]$VLC, [string]$File)
    
    Write-Host "$(Get-Date -Format 'HH:mm:ss') Playing audio with VLC..." -ForegroundColor Magenta
    
    try {
        # VLC command: play file, then quit after
        # --play-and-exit: quit after playing
        # --qt-start-minimized: don't show window (Qt interface)
        # --intf dummy: no interface
        $vlcArgs = "--play-and-exit --intf dummy `"$File`""
        
        $process = Start-Process -FilePath $VLC -ArgumentList $vlcArgs -PassThru -WindowStyle Hidden
        
        Write-Host "$(Get-Date -Format 'HH:mm:ss') VLC started (PID: $($process.Id))" -ForegroundColor Green
        
        # Wait for VLC to finish (max 20 seconds)
        $process | Wait-Process -Timeout 20 -ErrorAction SilentlyContinue
        
        if (-not $process.HasExited) {
            $process | Stop-Process -Force -ErrorAction SilentlyContinue
        }
        
        Write-Host "$(Get-Date -Format 'HH:mm:ss') Audio finished!" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "$(Get-Date -Format 'HH:mm:ss') VLC error: $_" -ForegroundColor Red
        return $false
    }
}

# Main loop
while ($true) {
    $checkCount++
    
    $acRunning = Is-ACRunning
    $serverConnected = Is-ConnectedToServer -IP $ServerIP
    $inGame = $acRunning -and $serverConnected
    
    # Status every 30 seconds
    if ($checkCount % 15 -eq 0) {
        $acStatus = if ($acRunning) { "Yes" } else { "No" }
        $srvStatus = if ($serverConnected) { "Yes" } else { "No" }
        Write-Host "$(Get-Date -Format 'HH:mm:ss') AC Running: $acStatus | Connected: $srvStatus" -ForegroundColor Gray
    }
    
    # Joined server
    if ($inGame -and -not $wasInGame) {
        Write-Host ""
        Write-Host "$(Get-Date -Format 'HH:mm:ss') =====================================" -ForegroundColor Green
        Write-Host "$(Get-Date -Format 'HH:mm:ss')  CONNECTED TO REDLINE SOULS!" -ForegroundColor Green
        Write-Host "$(Get-Date -Format 'HH:mm:ss') =====================================" -ForegroundColor Green
        
        if (-not $hasPlayed) {
            # Wait 20 seconds for game to fully load (loading screen -> pits)
            Write-Host "$(Get-Date -Format 'HH:mm:ss') Waiting 20 seconds for you to spawn in pits..." -ForegroundColor Yellow
            Start-Sleep -Seconds 20
            
            if ((Is-ACRunning) -and (Is-ConnectedToServer -IP $ServerIP)) {
                $hasPlayed = Play-WithVLC -VLC $VlcPath -File $AudioFile
            }
        }
        Write-Host ""
    }
    
    # Left server
    if (-not $inGame -and $wasInGame) {
        Write-Host "$(Get-Date -Format 'HH:mm:ss') Left server" -ForegroundColor Yellow
        $hasPlayed = $false
    }
    
    $wasInGame = $inGame
    Start-Sleep -Seconds 2
}
