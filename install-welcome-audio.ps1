# RedLine Souls - Welcome Audio Auto-Installer
# This script automatically downloads and installs the welcome audio to your Assetto Corsa folder

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RedLine Souls - Welcome Audio Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Direct link to the audio file on GitHub
$audioUrl = "https://raw.githubusercontent.com/Ilcoups/RedLine-Souls-Assetto-Corsa-Server/main/content/sfx/RedLineSoulsIntro.ogg"
$fileName = "RedLineSoulsIntro.ogg"

# Function to find Assetto Corsa installation
function Find-AssettoCorsa {
    Write-Host "Searching for Assetto Corsa installation..." -ForegroundColor Yellow
    
    # Common Steam library locations
    $steamPaths = @(
        "C:\Program Files (x86)\Steam\steamapps\common\assettocorsa",
        "C:\Program Files\Steam\steamapps\common\assettocorsa",
        "D:\Steam\steamapps\common\assettocorsa",
        "E:\Steam\steamapps\common\assettocorsa",
        "D:\SteamLibrary\steamapps\common\assettocorsa",
        "E:\SteamLibrary\steamapps\common\assettocorsa"
    )
    
    # Check each path
    foreach ($path in $steamPaths) {
        if (Test-Path "$path\acs.exe") {
            Write-Host "✓ Found Assetto Corsa at: $path" -ForegroundColor Green
            return $path
        }
    }
    
    # Try to find Steam library folders from registry
    try {
        $steamKey = Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam" -ErrorAction SilentlyContinue
        if ($steamKey) {
            $steamPath = $steamKey.InstallPath
            $acPath = "$steamPath\steamapps\common\assettocorsa"
            if (Test-Path "$acPath\acs.exe") {
                Write-Host "✓ Found Assetto Corsa at: $acPath" -ForegroundColor Green
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
    Write-Host "❌ Could not find Assetto Corsa installation automatically!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please enter your Assetto Corsa folder path manually:" -ForegroundColor Yellow
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

# Create sfx folder if it doesn't exist
$sfxPath = "$acPath\content\sfx"
if (-not (Test-Path $sfxPath)) {
    Write-Host ""
    Write-Host "Creating sfx folder..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $sfxPath -Force | Out-Null
}

$outputFile = "$sfxPath\$fileName"

# Download the audio file
Write-Host ""
Write-Host "Downloading welcome audio..." -ForegroundColor Yellow
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($audioUrl, $outputFile)
    
    if (Test-Path $outputFile) {
        $fileSize = (Get-Item $outputFile).Length / 1KB
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "✓ SUCCESS!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Audio file installed to:" -ForegroundColor Cyan
        Write-Host "$outputFile" -ForegroundColor White
        Write-Host ""
        Write-Host "File size: $([math]::Round($fileSize, 2)) KB" -ForegroundColor Gray
        Write-Host ""
        Write-Host "You will now hear the welcome audio when joining RedLine Souls server!" -ForegroundColor Green
        Write-Host "Server: 188.245.183.146:9600" -ForegroundColor Cyan
        Write-Host ""
    } else {
        throw "File download failed"
    }
} catch {
    Write-Host ""
    Write-Host "❌ Download failed: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "You can manually download from:" -ForegroundColor Yellow
    Write-Host "$audioUrl" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "And place it in:" -ForegroundColor Yellow
    Write-Host "$sfxPath" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
