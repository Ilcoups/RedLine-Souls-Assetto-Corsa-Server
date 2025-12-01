#Requires -Version 5.1
<#
.SYNOPSIS
    RedLine Souls - Spawn Audio Installer
    Automatically installs the spawn audio script for Assetto Corsa

.DESCRIPTION
    This script:
    1. Auto-detects your Assetto Corsa installation (Steam)
    2. Downloads the spawn audio Lua script from GitHub
    3. Installs it to the correct CSP folder
    4. You'll hear the RedLine Souls theme when joining the server!

.NOTES
    Author: RedLine Souls Team
    Server: RedLine Souls | Shuto Cruise
    Discord: https://discord.gg/YJJEGAhf

.EXAMPLE
    # Run directly from GitHub (recommended):
    irm https://raw.githubusercontent.com/Ilcoups/RedLine-Souls-Assetto-Corsa-Server/main/client_scripts/Install-RedLineAudio.ps1 | iex

    # Or download and run:
    .\Install-RedLineAudio.ps1
#>

[CmdletBinding()]
param(
    [string]$CustomACPath,
    [switch]$Force,
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

# ============================================================
# Configuration
# ============================================================
$ScriptVersion = "1.0.0"
$GitHubRepo = "Ilcoups/RedLine-Souls-Assetto-Corsa-Server"
$GitHubBranch = "main"
$LuaScriptPath = "client_scripts/redline_spawn_audio.lua"
$TargetFileName = "redline_spawn_audio.lua"

# GitHub raw URL for the Lua script
$LuaScriptUrl = "https://raw.githubusercontent.com/$GitHubRepo/$GitHubBranch/$LuaScriptPath"

# ============================================================
# Helper Functions
# ============================================================

function Write-Banner {
    $banner = @"

    ╔══════════════════════════════════════════════════════════╗
    ║                                                          ║
    ║   ██████╗ ███████╗██████╗ ██╗     ██╗███╗   ██╗███████╗  ║
    ║   ██╔══██╗██╔════╝██╔══██╗██║     ██║████╗  ██║██╔════╝  ║
    ║   ██████╔╝█████╗  ██║  ██║██║     ██║██╔██╗ ██║█████╗    ║
    ║   ██╔══██╗██╔══╝  ██║  ██║██║     ██║██║╚██╗██║██╔══╝    ║
    ║   ██║  ██║███████╗██████╔╝███████╗██║██║ ╚████║███████╗  ║
    ║   ╚═╝  ╚═╝╚══════╝╚═════╝ ╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝  ║
    ║                     SOULS                                 ║
    ║                                                          ║
    ║         🎵 Spawn Audio Installer v$ScriptVersion              ║
    ║                                                          ║
    ╚══════════════════════════════════════════════════════════╝

"@
    Write-Host $banner -ForegroundColor Red
}

function Write-Step {
    param([string]$Message, [string]$Status = "...")
    Write-Host "  [$Status] " -NoNewline -ForegroundColor Cyan
    Write-Host $Message
}

function Write-Success {
    param([string]$Message)
    Write-Host "  [✓] " -NoNewline -ForegroundColor Green
    Write-Host $Message -ForegroundColor Green
}

function Write-Error2 {
    param([string]$Message)
    Write-Host "  [✗] " -NoNewline -ForegroundColor Red
    Write-Host $Message -ForegroundColor Red
}

function Write-Warning2 {
    param([string]$Message)
    Write-Host "  [!] " -NoNewline -ForegroundColor Yellow
    Write-Host $Message -ForegroundColor Yellow
}

function Find-AssettoCorsaPath {
    <#
    .SYNOPSIS
        Auto-detect Assetto Corsa installation path
    #>
    
    $possiblePaths = @()
    
    # Method 1: Check Steam registry for library folders
    $steamPath = $null
    $steamRegPaths = @(
        "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
        "HKLM:\SOFTWARE\Valve\Steam",
        "HKCU:\SOFTWARE\Valve\Steam"
    )
    
    foreach ($regPath in $steamRegPaths) {
        try {
            $steamPath = (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue).InstallPath
            if ($steamPath) { break }
        } catch { }
    }
    
    if ($steamPath) {
        # Default Steam library
        $possiblePaths += Join-Path $steamPath "steamapps\common\assettocorsa"
        
        # Check libraryfolders.vdf for additional Steam libraries
        $libraryFoldersPath = Join-Path $steamPath "steamapps\libraryfolders.vdf"
        if (Test-Path $libraryFoldersPath) {
            $content = Get-Content $libraryFoldersPath -Raw
            # Match paths in libraryfolders.vdf (both old and new format)
            $matches = [regex]::Matches($content, '"path"\s+"([^"]+)"')
            foreach ($match in $matches) {
                $libPath = $match.Groups[1].Value -replace '\\\\', '\'
                $possiblePaths += Join-Path $libPath "steamapps\common\assettocorsa"
            }
            # Also try old format
            $matches = [regex]::Matches($content, '"\d+"\s+"([A-Za-z]:\\[^"]+)"')
            foreach ($match in $matches) {
                $libPath = $match.Groups[1].Value -replace '\\\\', '\'
                $possiblePaths += Join-Path $libPath "steamapps\common\assettocorsa"
            }
        }
    }
    
    # Method 2: Common installation paths
    $drives = @("C:", "D:", "E:", "F:", "G:")
    foreach ($drive in $drives) {
        $possiblePaths += "$drive\SteamLibrary\steamapps\common\assettocorsa"
        $possiblePaths += "$drive\Steam\steamapps\common\assettocorsa"
        $possiblePaths += "$drive\Games\Steam\steamapps\common\assettocorsa"
        $possiblePaths += "$drive\Program Files\Steam\steamapps\common\assettocorsa"
        $possiblePaths += "$drive\Program Files (x86)\Steam\steamapps\common\assettocorsa"
    }
    
    # Remove duplicates and check which paths exist
    $possiblePaths = $possiblePaths | Select-Object -Unique
    
    foreach ($path in $possiblePaths) {
        if (Test-Path (Join-Path $path "AssettoCorsa.exe")) {
            return $path
        }
        # Also check without exe (folder exists)
        if (Test-Path $path) {
            # Verify it's actually AC
            if ((Test-Path (Join-Path $path "acs.exe")) -or 
                (Test-Path (Join-Path $path "AssettoCorsa.exe")) -or
                (Test-Path (Join-Path $path "content"))) {
                return $path
            }
        }
    }
    
    return $null
}

function Get-DocumentsPath {
    <#
    .SYNOPSIS
        Get the user's Documents folder path (handles OneDrive redirection)
    #>
    
    # Try the shell folder first (handles OneDrive)
    try {
        $shell = New-Object -ComObject Shell.Application
        $documentsFolder = $shell.Namespace(0x05)  # Personal/Documents
        if ($documentsFolder) {
            return $documentsFolder.Self.Path
        }
    } catch { }
    
    # Fallback to environment variable
    $docs = [Environment]::GetFolderPath('MyDocuments')
    if ($docs) { return $docs }
    
    # Last resort
    return Join-Path $env:USERPROFILE "Documents"
}

function Install-SpawnAudioScript {
    param(
        [string]$ACPath,
        [switch]$Force
    )
    
    # Determine target directory
    # CSP Lua scripts go in: Documents\Assetto Corsa\cfg\lua\online\
    $documentsPath = Get-DocumentsPath
    $cspLuaPath = Join-Path $documentsPath "Assetto Corsa\cfg\lua\online"
    
    Write-Step "Target folder: $cspLuaPath"
    
    # Create directory if it doesn't exist
    if (-not (Test-Path $cspLuaPath)) {
        Write-Step "Creating CSP Lua folder..."
        New-Item -ItemType Directory -Path $cspLuaPath -Force | Out-Null
        Write-Success "Created folder"
    }
    
    $targetFile = Join-Path $cspLuaPath $TargetFileName
    
    # Check if already installed
    if ((Test-Path $targetFile) -and -not $Force) {
        Write-Warning2 "Script already installed at: $targetFile"
        $response = Read-Host "  Overwrite? (y/N)"
        if ($response -notmatch '^[Yy]') {
            Write-Step "Installation cancelled"
            return $false
        }
    }
    
    # Download the Lua script from GitHub
    Write-Step "Downloading from GitHub..."
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "RedLine-Souls-Installer")
        $luaContent = $webClient.DownloadString($LuaScriptUrl)
        
        if ([string]::IsNullOrWhiteSpace($luaContent)) {
            throw "Downloaded content is empty"
        }
        
        Write-Success "Downloaded successfully"
    }
    catch {
        Write-Error2 "Failed to download: $_"
        Write-Host ""
        Write-Host "  Try downloading manually from:" -ForegroundColor Yellow
        Write-Host "  $LuaScriptUrl" -ForegroundColor Cyan
        return $false
    }
    
    # Save the script
    Write-Step "Installing script..."
    try {
        # Use UTF8 without BOM for Lua compatibility
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($targetFile, $luaContent, $utf8NoBom)
        Write-Success "Installed to: $targetFile"
    }
    catch {
        Write-Error2 "Failed to save script: $_"
        return $false
    }
    
    return $true
}

function Uninstall-SpawnAudioScript {
    $documentsPath = Get-DocumentsPath
    $targetFile = Join-Path $documentsPath "Assetto Corsa\cfg\lua\online\$TargetFileName"
    
    if (Test-Path $targetFile) {
        Remove-Item $targetFile -Force
        Write-Success "Removed: $targetFile"
        return $true
    }
    else {
        Write-Warning2 "Script not found, nothing to uninstall"
        return $false
    }
}

# ============================================================
# Main Execution
# ============================================================

Write-Banner

if ($Uninstall) {
    Write-Host "  Uninstalling RedLine Souls Spawn Audio..." -ForegroundColor Yellow
    Write-Host ""
    Uninstall-SpawnAudioScript
    Write-Host ""
    Write-Host "  Done! Script has been removed." -ForegroundColor Green
    exit 0
}

Write-Host "  Installing RedLine Souls Spawn Audio..." -ForegroundColor Yellow
Write-Host ""

# Step 1: Find Assetto Corsa
Write-Step "Detecting Assetto Corsa installation..."

$acPath = $null
if ($CustomACPath) {
    if (Test-Path $CustomACPath) {
        $acPath = $CustomACPath
        Write-Success "Using custom path: $acPath"
    }
    else {
        Write-Error2 "Custom path not found: $CustomACPath"
        exit 1
    }
}
else {
    $acPath = Find-AssettoCorsaPath
    if ($acPath) {
        Write-Success "Found AC at: $acPath"
    }
    else {
        Write-Warning2 "Could not auto-detect Assetto Corsa"
        Write-Host ""
        Write-Host "  Please enter your AC installation path:" -ForegroundColor Yellow
        Write-Host "  Example: D:\SteamLibrary\steamapps\common\assettocorsa" -ForegroundColor Gray
        $acPath = Read-Host "  Path"
        
        if (-not (Test-Path $acPath)) {
            Write-Error2 "Path does not exist: $acPath"
            exit 1
        }
    }
}

# Step 2: Check for CSP
Write-Step "Checking for Custom Shaders Patch..."
$cspIndicators = @(
    (Join-Path $acPath "extension"),
    (Join-Path $acPath "extension\config"),
    (Join-Path $acPath "system\x64\dwrite.dll")
)

$hasCSP = $false
foreach ($indicator in $cspIndicators) {
    if (Test-Path $indicator) {
        $hasCSP = $true
        break
    }
}

if ($hasCSP) {
    Write-Success "CSP detected"
}
else {
    Write-Warning2 "CSP not detected (script may not work without CSP)"
}

# Step 3: Install the script
Write-Host ""
$result = Install-SpawnAudioScript -ACPath $acPath -Force:$Force

Write-Host ""
if ($result) {
    Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "  ║                                                          ║" -ForegroundColor Green
    Write-Host "  ║   ✅ INSTALLATION COMPLETE!                              ║" -ForegroundColor Green
    Write-Host "  ║                                                          ║" -ForegroundColor Green
    Write-Host "  ║   Next steps:                                            ║" -ForegroundColor Green
    Write-Host "  ║   1. Start/Restart Assetto Corsa                         ║" -ForegroundColor Green
    Write-Host "  ║   2. Join RedLine Souls server                           ║" -ForegroundColor Green
    Write-Host "  ║   3. Enjoy the spawn audio! 🎵                           ║" -ForegroundColor Green
    Write-Host "  ║                                                          ║" -ForegroundColor Green
    Write-Host "  ║   Discord: https://discord.gg/YJJEGAhf                   ║" -ForegroundColor Green
    Write-Host "  ║                                                          ║" -ForegroundColor Green
    Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
}
else {
    Write-Host "  Installation failed. Please try again or install manually." -ForegroundColor Red
    exit 1
}

Write-Host ""
