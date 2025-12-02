#Requires -Version 5.1
# RedLine Souls Audio v3.3 - Lightweight background service

$AudioFile = "$env:USERPROFILE\Documents\RedLineSouls\RedLineSoulsIntro.ogg"
$LockFile = "$env:TEMP\redline_audio_played.lock"

# Find VLC
$VlcPath = @(
    "${env:ProgramFiles}\VideoLAN\VLC\vlc.exe",
    "${env:ProgramFiles(x86)}\VideoLAN\VLC\vlc.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $VlcPath -or -not (Test-Path $AudioFile)) { exit }

# Clean old lock if AC not running
if (-not (Get-Process -Name "acs" -ErrorAction SilentlyContinue) -and (Test-Path $LockFile)) {
    Remove-Item $LockFile -Force
}

# Main loop - check every 5 seconds
while ($true) {
    $acProc = Get-Process -Name "acs" -ErrorAction SilentlyContinue
    
    if ($acProc -and -not (Test-Path $LockFile)) {
        Start-Sleep -Seconds 40
        if (Get-Process -Name "acs" -ErrorAction SilentlyContinue) {
            "played" | Out-File $LockFile
            Start-Process -FilePath $VlcPath -ArgumentList "--play-and-exit", "--intf", "dummy", "`"$AudioFile`"" -WindowStyle Hidden
        }
    }
    elseif (-not $acProc -and (Test-Path $LockFile)) {
        Remove-Item $LockFile -Force
    }
    
    Start-Sleep -Seconds 5
}
