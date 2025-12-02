# RedLine Souls Audio Monitor v2.6
# Plays audio using VLC when you SPAWN in the server (not just connect)

param(
    [string]$ServerIP = "188.245.183.146"
)

$InstallDir = "$env:USERPROFILE\Documents\RedLineSouls"
$AudioFile = "$InstallDir\RedLineSoulsIntro.ogg"

# AC Log file location
$ACLogPath = "$env:USERPROFILE\Documents\Assetto Corsa\logs\log.txt"

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
Write-Host "   RedLine Souls Audio Monitor v2.6" -ForegroundColor Red  
Write-Host "==========================================" -ForegroundColor Red
Write-Host ""
Write-Host "  Server: $ServerIP" -ForegroundColor Gray
Write-Host "  Audio:  $AudioFile" -ForegroundColor Gray

if ($VlcPath) {
    Write-Host "  VLC:    Found" -ForegroundColor Green
} else {
    Write-Host "  VLC:    NOT FOUND!" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Install VLC: https://www.videolan.org/vlc/" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

if (-not (Test-Path $AudioFile)) {
    Write-Host "  Audio:  NOT FOUND!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "  Audio:  Found" -ForegroundColor Green

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Waiting for you to spawn on server..." -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$hasPlayed = $false
$wasConnected = $false
$lastLogSize = 0
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

function Check-Spawned {
    # Check AC log for spawn indicators
    # When you spawn, the log shows things like "SENDING SPAWN" or car loading complete
    param([string]$LogPath, [ref]$LastSize)
    
    if (-not (Test-Path $LogPath)) {
        return $false
    }
    
    try {
        $file = Get-Item $LogPath
        $currentSize = $file.Length
        
        # If log grew, check new content
        if ($currentSize -gt $LastSize.Value) {
            $stream = [System.IO.File]::Open($LogPath, 'Open', 'Read', 'ReadWrite')
            $reader = New-Object System.IO.StreamReader($stream)
            
            # Seek to where we last read
            if ($LastSize.Value -gt 0) {
                $stream.Seek($LastSize.Value, 'Begin') | Out-Null
            }
            
            $newContent = $reader.ReadToEnd()
            $reader.Close()
            $stream.Close()
            
            $LastSize.Value = $currentSize
            
            # Look for spawn indicators in the new log content
            # "CAR_spawn" or "ksPhysics" loading or going on track
            if ($newContent -match "SESSION_INFO" -or $newContent -match "SPAWN" -or $newContent -match "Going to") {
                return $true
            }
        }
    } catch {
        # Ignore errors reading log
    }
    
    return $false
}

function Play-WithVLC {
    param([string]$VLC, [string]$File)
    
    Write-Host "$(Get-Date -Format 'HH:mm:ss') Playing audio..." -ForegroundColor Magenta
    
    try {
        $vlcArgs = "--play-and-exit --intf dummy `"$File`""
        $process = Start-Process -FilePath $VLC -ArgumentList $vlcArgs -PassThru -WindowStyle Hidden
        
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
        Write-Host "$(Get-Date -Format 'HH:mm:ss') AC: $acStatus | Server: $srvStatus" -ForegroundColor Gray
    }
    
    # Just connected to server
    if ($inGame -and -not $wasConnected) {
        Write-Host ""
        Write-Host "$(Get-Date -Format 'HH:mm:ss') Connected! Waiting for spawn..." -ForegroundColor Yellow
        
        # Reset log position to current
        if (Test-Path $ACLogPath) {
            $lastLogSize = (Get-Item $ACLogPath).Length
        }
    }
    
    # While connected, check if spawned
    if ($inGame -and -not $hasPlayed) {
        $spawned = Check-Spawned -LogPath $ACLogPath -LastSize ([ref]$lastLogSize)
        
        if ($spawned) {
            Write-Host ""
            Write-Host "$(Get-Date -Format 'HH:mm:ss') =====================================" -ForegroundColor Green
            Write-Host "$(Get-Date -Format 'HH:mm:ss')  SPAWNED IN REDLINE SOULS!" -ForegroundColor Green
            Write-Host "$(Get-Date -Format 'HH:mm:ss') =====================================" -ForegroundColor Green
            
            # Small delay to make sure audio system is ready
            Start-Sleep -Seconds 2
            
            $hasPlayed = Play-WithVLC -VLC $VlcPath -File $AudioFile
            Write-Host ""
        }
    }
    
    # Left server - reset
    if (-not $inGame -and $wasConnected) {
        Write-Host "$(Get-Date -Format 'HH:mm:ss') Disconnected" -ForegroundColor Yellow
        $hasPlayed = $false
        $lastLogSize = 0
    }
    
    $wasConnected = $inGame
    Start-Sleep -Seconds 1
}
