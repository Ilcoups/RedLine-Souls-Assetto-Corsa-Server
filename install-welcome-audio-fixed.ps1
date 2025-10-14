# RedLine Souls - Welcome Audio Installer (Fixed for D: drive)
# This installs the Lua script in the AC apps folder where it will actually work

Write-Host ""
Write-Host "RedLine Souls - Welcome Audio Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Your AC installation path
$acPath = "D:\SteamLibrary\steamapps\common\assettocorsa"

# Check if AC exists
if (-not (Test-Path "$acPath\acs.exe")) {
    Write-Host "ERROR: Assetto Corsa not found at $acPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "Found Assetto Corsa at: $acPath" -ForegroundColor Green
Write-Host ""

# Step 1: Check audio file
Write-Host "[1/2] Checking audio file..." -ForegroundColor Yellow
$audioFile = "$acPath\content\sfx\RedLineSoulsIntro.ogg"

if (Test-Path $audioFile) {
    $fileSize = (Get-Item $audioFile).Length / 1KB
    Write-Host "      Audio file found ($([math]::Round($fileSize, 2)) KB)" -ForegroundColor Green
} else {
    Write-Host "      Audio file NOT found!" -ForegroundColor Red
    Write-Host "      Downloading audio file..." -ForegroundColor Yellow
    
    $sfxPath = "$acPath\content\sfx"
    if (-not (Test-Path $sfxPath)) {
        New-Item -ItemType Directory -Path $sfxPath -Force | Out-Null
    }
    
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $audioUrl = "https://raw.githubusercontent.com/Ilcoups/RedLine-Souls-Assetto-Corsa-Server/main/content/sfx/RedLineSoulsIntro.ogg"
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($audioUrl, $audioFile)
        Write-Host "      Audio file downloaded!" -ForegroundColor Green
    } catch {
        Write-Host "      ERROR: Could not download audio file: $_" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""

# Step 2: Install Lua script in apps folder
Write-Host "[2/2] Installing Lua script..." -ForegroundColor Yellow

$luaAppPath = "$acPath\apps\lua\welcome_sound"
if (-not (Test-Path $luaAppPath)) {
    New-Item -ItemType Directory -Path $luaAppPath -Force | Out-Null
}

$luaScript = @'
-- RedLine Souls Welcome Audio
-- Plays welcome sound 3 seconds after joining

local played = false
local timer = 0

function script.update(dt)
    if played then return end
    timer = timer + dt
    
    if timer >= 3 then
        ui.playSound('content/sfx/RedLineSoulsIntro.ogg', 1.0)
        played = true
    end
end
'@

$luaFile = "$luaAppPath\welcome_sound.lua"

try {
    $luaScript | Out-File -FilePath $luaFile -Encoding UTF8 -Force
    Write-Host "      Lua script installed!" -ForegroundColor Green
} catch {
    Write-Host "      ERROR: Could not create Lua script: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "INSTALLATION COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Files installed:" -ForegroundColor Cyan
Write-Host "  Audio: $audioFile" -ForegroundColor White
Write-Host "  Script: $luaFile" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Restart Assetto Corsa (if running)" -ForegroundColor White
Write-Host "2. Join RedLine Souls server: 188.245.183.146:9600" -ForegroundColor White
Write-Host "3. Audio will play after 3 seconds!" -ForegroundColor White
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

