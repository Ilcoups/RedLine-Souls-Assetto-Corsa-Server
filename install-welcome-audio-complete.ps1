# RedLine Souls - Complete Welcome Audio Installer
# This script installs BOTH the audio file AND the Lua script for guaranteed audio playback

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RedLine Souls - Complete Audio Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$audioUrl = "https://raw.githubusercontent.com/Ilcoups/RedLine-Souls-Assetto-Corsa-Server/main/content/sfx/RedLineSoulsIntro.ogg"
$luaUrl = "https://raw.githubusercontent.com/Ilcoups/RedLine-Souls-Assetto-Corsa-Server/main/redline_souls_welcome.lua"
$audioFileName = "RedLineSoulsIntro.ogg"
$luaFileName = "redline_souls_welcome.lua"

# Function to find Assetto Corsa installation
function Find-AssettoCorsa {
    Write-Host "[1/3] Searching for Assetto Corsa installation..." -ForegroundColor Yellow
    
    $steamPaths = @(
        "C:\Program Files (x86)\Steam\steamapps\common\assettocorsa",
        "C:\Program Files\Steam\steamapps\common\assettocorsa",
        "D:\Steam\steamapps\common\assettocorsa",
        "E:\Steam\steamapps\common\assettocorsa",
        "D:\SteamLibrary\steamapps\common\assettocorsa",
        "E:\SteamLibrary\steamapps\common\assettocorsa",
        "F:\SteamLibrary\steamapps\common\assettocorsa"
    )
    
    foreach ($path in $steamPaths) {
        if (Test-Path "$path\acs.exe") {
            Write-Host "      ✓ Found at: $path" -ForegroundColor Green
            return $path
        }
    }
    
    try {
        $steamKey = Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam" -ErrorAction SilentlyContinue
        if ($steamKey) {
            $steamPath = $steamKey.InstallPath
            $acPath = "$steamPath\steamapps\common\assettocorsa"
            if (Test-Path "$acPath\acs.exe") {
                Write-Host "      ✓ Found at: $acPath" -ForegroundColor Green
                return $acPath
            }
        }
    } catch {}
    
    return $null
}

# Find AC installation
$acPath = Find-AssettoCorsa

if (-not $acPath) {
    Write-Host ""
    Write-Host "❌ Could not find Assetto Corsa automatically!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please enter your Assetto Corsa folder path:" -ForegroundColor Yellow
    Write-Host "Example: C:\Program Files (x86)\Steam\steamapps\common\assettocorsa" -ForegroundColor Gray
    Write-Host ""
    $acPath = Read-Host "AC Path"
    
    if (-not (Test-Path "$acPath\acs.exe")) {
        Write-Host ""
        Write-Host "❌ Invalid path! acs.exe not found!" -ForegroundColor Red
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
}

Write-Host ""

# Step 1: Install audio file
Write-Host "[2/3] Installing audio file..." -ForegroundColor Yellow

$sfxPath = "$acPath\content\sfx"
if (-not (Test-Path $sfxPath)) {
    New-Item -ItemType Directory -Path $sfxPath -Force | Out-Null
}

$audioFile = "$sfxPath\$audioFileName"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($audioUrl, $audioFile)
    
    if (Test-Path $audioFile) {
        $fileSize = (Get-Item $audioFile).Length / 1KB
        Write-Host "      ✓ Audio file installed ($([math]::Round($fileSize, 2)) KB)" -ForegroundColor Green
    } else {
        throw "Audio download failed"
    }
} catch {
    Write-Host "      ❌ Audio download failed: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual download: $audioUrl" -ForegroundColor Yellow
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host ""

# Step 2: Install Lua script
Write-Host "[3/3] Installing Lua script..." -ForegroundColor Yellow

$documentsPath = [Environment]::GetFolderPath("MyDocuments")
$luaPath = "$documentsPath\Assetto Corsa\cfg\lua\online"

if (-not (Test-Path "$documentsPath\Assetto Corsa")) {
    Write-Host "      ⚠️  AC documents folder not found!" -ForegroundColor Yellow
    Write-Host "      Please launch Assetto Corsa at least once first." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "      Audio file was installed, but Lua script needs AC to be launched first." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 0
}

if (-not (Test-Path $luaPath)) {
    New-Item -ItemType Directory -Path $luaPath -Force | Out-Null
}

$luaFile = "$luaPath\$luaFileName"

try {
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($luaUrl, $luaFile)
    
    if (Test-Path $luaFile) {
        Write-Host "      ✓ Lua script installed" -ForegroundColor Green
    } else {
        throw "Lua download failed"
    }
} catch {
    Write-Host "      ❌ Lua download failed: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual download: $luaUrl" -ForegroundColor Yellow
    Write-Host "Save to: $luaPath" -ForegroundColor Yellow
}

# Success message
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "✓ INSTALLATION COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Installed files:" -ForegroundColor Cyan
Write-Host "  • Audio: $audioFile" -ForegroundColor White
Write-Host "  • Script: $luaFile" -ForegroundColor White
Write-Host ""
Write-Host "What happens now:" -ForegroundColor Yellow
Write-Host "  1. Restart Assetto Corsa (if running)" -ForegroundColor White
Write-Host "  2. Join RedLine Souls server" -ForegroundColor White
Write-Host "  3. Welcome audio will play after 3 seconds!" -ForegroundColor White
Write-Host ""
Write-Host "Server: 188.245.183.146:9600" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

