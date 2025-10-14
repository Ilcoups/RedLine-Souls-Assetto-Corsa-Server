# RedLine Souls - Lua Script Only Installer
# Use this if you already have the audio file installed

Write-Host ""
Write-Host "RedLine Souls - Lua Script Installer" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

$luaUrl = "https://raw.githubusercontent.com/Ilcoups/RedLine-Souls-Assetto-Corsa-Server/main/redline_souls_welcome.lua"
$luaFileName = "redline_souls_welcome.lua"

$documentsPath = [Environment]::GetFolderPath("MyDocuments")
$luaPath = "$documentsPath\Assetto Corsa\cfg\lua\online"

if (-not (Test-Path "$documentsPath\Assetto Corsa")) {
    Write-Host "❌ Assetto Corsa documents folder not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please launch Assetto Corsa at least once first." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "Installing Lua script..." -ForegroundColor Yellow

if (-not (Test-Path $luaPath)) {
    New-Item -ItemType Directory -Path $luaPath -Force | Out-Null
}

$luaFile = "$luaPath\$luaFileName"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($luaUrl, $luaFile)
    
    if (Test-Path $luaFile) {
        Write-Host ""
        Write-Host "✓ SUCCESS!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Lua script installed to:" -ForegroundColor Cyan
        Write-Host "$luaFile" -ForegroundColor White
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "1. Restart Assetto Corsa (if running)" -ForegroundColor White
        Write-Host "2. Join RedLine Souls: 188.245.183.146:9600" -ForegroundColor White
        Write-Host "3. Audio will play after 3 seconds!" -ForegroundColor White
        Write-Host ""
    } else {
        throw "Download failed"
    }
} catch {
    Write-Host ""
    Write-Host "❌ Download failed: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual download: $luaUrl" -ForegroundColor Yellow
    Write-Host "Save to: $luaPath" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

