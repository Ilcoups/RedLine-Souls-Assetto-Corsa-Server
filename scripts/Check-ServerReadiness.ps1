# Windows Game Server Readiness Checker
# Version: 0.1.0

param(
    [string]$ServerHost,
    [int[]]$TcpPorts,
    [int[]]$UdpPorts,
    [ValidateSet('steam','path','none')]
    [string]$ClientType = 'none',
    [int]$SteamAppId,
    [string]$ClientExePath,
    [string]$OutDir,
    [string]$ConfigPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-OutputDirectory {
    param([string]$RequestedPath)
    if ([string]::IsNullOrWhiteSpace($RequestedPath)) {
        $base = Join-Path -Path $env:TEMP -ChildPath ("readiness_" + (Get-Date -Format 'yyyyMMdd_HHmmss'))
    } else {
        $base = $RequestedPath
    }
    if (-not (Test-Path -LiteralPath $base)) { [void](New-Item -ItemType Directory -Path $base) }
    return (Resolve-Path -LiteralPath $base).Path
}

function Initialize-Logger {
    param([string]$DirectoryPath)
    $script:LogPath = Join-Path $DirectoryPath 'readiness.log'
    $script:Redactions = @{
        $env:USERNAME   = '<USER>'
        $env:USERPROFILE = '<USERPROFILE>'
    }
    "[#] Readiness started $(Get-Date -Format o)" | Out-File -FilePath $script:LogPath -Encoding UTF8
}

function Write-Log {
    param([string]$Message, [ValidateSet('INFO','WARN','ERROR','OK')][string]$Level = 'INFO')
    $line = "[$Level] $Message"
    foreach ($k in $script:Redactions.Keys) { $line = $line -replace [Regex]::Escape($k), $script:Redactions[$k] }
    $line | Out-File -FilePath $script:LogPath -Append -Encoding UTF8
    switch ($Level) {
        'ERROR' { Write-Host $line -ForegroundColor Red }
        'WARN'  { Write-Host $line -ForegroundColor Yellow }
        'OK'    { Write-Host $line -ForegroundColor Green }
        default { Write-Host $line }
    }
}

function Load-Config {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) { return $null }
    try {
        return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        Write-Log "Failed to parse config at $Path: $($_.Exception.Message)" 'WARN'
        return $null
    }
}

function Merge-Config {
    param($Defaults, $Overrides)
    if (-not $Overrides) { return $Defaults }
    $merged = [ordered]@{}
    foreach ($k in $Defaults.PSObject.Properties.Name) { $merged[$k] = $Defaults.$k }
    foreach ($k in $Overrides.PSObject.Properties.Name) { $merged[$k] = $Overrides.$k }
    return [pscustomobject]$merged
}

function Get-DefaultConfig {
    $defaults = [pscustomobject]@{
        ServerHost   = 'your.server.example'
        TcpPorts     = @(9600,9601)
        UdpPorts     = @()
        ClientChecks = [pscustomobject]@{
            Type       = 'none'
            SteamAppId = 244210
            ExePath    = 'C:\\Path\\To\\YourClient.exe'
        }
    }
    return $defaults
}

function Coalesce-Parameters {
    param($Config)
    $c = [pscustomobject]@{
        ServerHost   = if ($ServerHost) { $ServerHost } else { $Config.ServerHost }
        TcpPorts     = if ($TcpPorts) { $TcpPorts } else { $Config.TcpPorts }
        UdpPorts     = if ($UdpPorts) { $UdpPorts } else { $Config.UdpPorts }
        ClientChecks = [pscustomobject]@{
            Type       = if ($ClientType) { $ClientType } else { $Config.ClientChecks.Type }
            SteamAppId = if ($SteamAppId) { $SteamAppId } else { $Config.ClientChecks.SteamAppId }
            ExePath    = if ($ClientExePath) { $ClientExePath } else { $Config.ClientChecks.ExePath }
        }
    }
    return $c
}

function Test-System {
    param($Results)
    Write-Log 'Running system checks...'
    $sys = [ordered]@{}
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $sys['OSCaption'] = $os.Caption
        $sys['OSVersion'] = $os.Version
        $sys['BuildNumber'] = $os.BuildNumber
    } catch { Write-Log "OS query failed: $($_.Exception.Message)" 'WARN' }
    $sys['PSVersion'] = $PSVersionTable.PSVersion.ToString()
    try {
        $execPol = Get-ExecutionPolicy -Scope Process
        $sys['ExecutionPolicy'] = $execPol
    } catch { Write-Log "ExecutionPolicy query failed: $($_.Exception.Message)" 'WARN' }
    try {
        $timeSync = (w32tm /query /status) 2>$null
        $sys['TimeService'] = ($timeSync | Out-String).Trim()
    } catch { $sys['TimeService'] = 'w32tm not available or failed' }
    $Results.System = $sys
    $Results.Summary += @([pscustomobject]@{ Name='System'; Passed=$true; Detail='Collected OS, PS version, time sync' })
}

function Resolve-Host {
    param([string]$Host)
    try {
        if (Get-Command Resolve-DnsName -ErrorAction SilentlyContinue) {
            $r = Resolve-DnsName -Name $Host -ErrorAction Stop
            return $r.IPAddress | Select-Object -Unique
        } else {
            return [System.Net.Dns]::GetHostAddresses($Host).IPAddressToString
        }
    } catch { return @() }
}

function Test-Network {
    param($Results, [string]$Host, [int[]]$TcpPorts, [int[]]$UdpPorts)
    Write-Log 'Running network checks...'
    $net = [ordered]@{}
    $ips = Resolve-Host -Host $Host
    $net['DnsResolved'] = @($ips)
    if ($ips.Count -gt 0) { Write-Log "DNS resolved $Host => $($ips -join ', ')" 'OK' } else { Write-Log "DNS failed for $Host" 'ERROR' }

    try {
        $pings = Test-Connection -TargetName $Host -Count 4 -Quiet:$false -ErrorAction Stop
        $stats = $pings | Measure-Object -Property ResponseTime -Average -Minimum -Maximum
        $lat = [pscustomobject]@{ MinMs=$stats.Minimum; AvgMs=[math]::Round($stats.Average,2); MaxMs=$stats.Maximum }
        $net['Ping'] = $lat
        Write-Log "Ping latency ms: min=$($lat.MinMs) avg=$($lat.AvgMs) max=$($lat.MaxMs)" 'OK'
    } catch { Write-Log "Ping failed: $($_.Exception.Message)" 'WARN' }

    $tcpResults = @()
    foreach ($port in $TcpPorts) {
        try {
            $tnc = Test-NetConnection -ComputerName $Host -Port $port -WarningAction SilentlyContinue
            $ok = $false
            if ($tnc -and ($tnc.TcpTestSucceeded -eq $true)) { $ok = $true }
            $tcpResults += [pscustomobject]@{ Port=$port; Reachable=$ok }
            Write-Log "TCP $port => $ok" ($ok ? 'OK' : 'ERROR')
        } catch {
            $tcpResults += [pscustomobject]@{ Port=$port; Reachable=$false }
            Write-Log "TCP test error on $port: $($_.Exception.Message)" 'ERROR'
        }
    }
    $net['TcpPorts'] = $tcpResults

    $udpResults = @()
    foreach ($port in $UdpPorts) {
        $udpOk = $false
        try {
            $client = New-Object System.Net.Sockets.UdpClient
            $client.Client.ReceiveTimeout = 500
            $client.Connect($Host, $port)
            $bytes = [Text.Encoding]::ASCII.GetBytes('probe')
            [void]$client.Send($bytes, $bytes.Length)
            $udpOk = $true
            $client.Close()
        } catch { $udpOk = $false }
        $udpResults += [pscustomobject]@{ Port=$port; SentProbe=$udpOk; Note='UDP is stateless; result advisory' }
        Write-Log "UDP $port probe sent=$udpOk (advisory)" ($udpOk ? 'OK' : 'WARN')
    }
    $net['UdpPorts'] = $udpResults

    try {
        $trPath = Join-Path $OutDir 'tracert.txt'
        tracert -d -h 15 $Host | Out-File -FilePath $trPath -Encoding UTF8
        $net['TraceroutePath'] = $trPath
        Write-Log "Traceroute saved: $trPath" 'OK'
    } catch { Write-Log "Traceroute failed: $($_.Exception.Message)" 'WARN' }

    try {
        $ghOk = $false
        $url = 'https://raw.githubusercontent.com'
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            $resp = Invoke-WebRequest -Method Head -Uri $url -TimeoutSec 10
        } else {
            $resp = Invoke-WebRequest -UseBasicParsing -Method Head -Uri $url -TimeoutSec 10
        }
        if ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 400) { $ghOk = $true }
        $net['GitHubReachable'] = $ghOk
        Write-Log "GitHub reachability: $ghOk" ($ghOk ? 'OK' : 'WARN')
    } catch { Write-Log "GitHub reachability check failed: $($_.Exception.Message)" 'WARN' }

    $Results.Network = $net
    $tcpPass = ($tcpResults | Where-Object { $_.Reachable -eq $false }).Count -eq 0
    $Results.Summary += @([pscustomobject]@{ Name='Network'; Passed=$tcpPass; Detail='DNS/Ping/TCP/UDP/Traceroute collected' })
}

function Test-Firewall {
    param($Results, [string]$ExePath)
    Write-Log 'Running firewall checks...'
    $fw = [ordered]@{}
    try {
        $profiles = Get-NetFirewallProfile -ErrorAction Stop | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction
        $fw['Profiles'] = $profiles
        Write-Log "Firewall profiles collected" 'OK'
    } catch { Write-Log "Firewall profile query failed: $($_.Exception.Message)" 'WARN' }
    if ($ExePath -and (Test-Path -LiteralPath $ExePath)) {
        try {
            $rules = Get-NetFirewallRule -ErrorAction Stop | Get-NetFirewallApplicationFilter | Where-Object { $_.Program -ieq $ExePath }
            $fw['RulesForExe'] = $rules
            Write-Log "Found $($rules.Count) firewall rule(s) for exe" 'OK'
        } catch { Write-Log "Firewall rule query failed: $($_.Exception.Message)" 'WARN' }
    }
    $Results.Firewall = $fw
    $Results.Summary += @([pscustomobject]@{ Name='Firewall'; Passed=$true; Detail='Collected firewall profiles and rules' })
}

function Read-SteamLibraries {
    $libs = @()
    try {
        $steamRoot = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam' -Name InstallPath -ErrorAction Stop).InstallPath
        $libs += (Join-Path $steamRoot 'steamapps')
    } catch {}
    try {
        $steamRootCU = (Get-ItemProperty -Path 'HKCU:\SOFTWARE\Valve\Steam' -Name SteamPath -ErrorAction Stop).SteamPath
        $libs += (Join-Path $steamRootCU 'steamapps')
    } catch {}
    $libs = $libs | Select-Object -Unique
    # Parse libraryfolders.vdf for additional libraries
    foreach ($root in $libs) {
        $vdf = Join-Path (Split-Path $root -Parent) 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf) {
            try {
                $content = Get-Content -LiteralPath $vdf -Raw
                $matches = [regex]::Matches($content, '"path"\s*"([^"]+)"')
                foreach ($m in $matches) {
                    $path = $m.Groups[1].Value
                    $libs += (Join-Path $path 'steamapps')
                }
            } catch {}
        }
    }
    return ($libs | Select-Object -Unique)
}

function Test-Client {
    param($Results, [pscustomobject]$ClientChecks)
    Write-Log 'Running client checks...'
    $client = [ordered]@{ Type=$ClientChecks.Type }
    $pass = $true
    switch ($ClientChecks.Type) {
        'path' {
            $client['ExePath'] = $ClientChecks.ExePath
            $exists = $false
            if ($ClientChecks.ExePath) { $exists = Test-Path -LiteralPath $ClientChecks.ExePath }
            $client['Exists'] = $exists
            $pass = $exists
            Write-Log ("Client exe present: $exists at '" + $ClientChecks.ExePath + "'") ($exists ? 'OK' : 'ERROR')
        }
        'steam' {
            $client['SteamAppId'] = $ClientChecks.SteamAppId
            $libs = Read-SteamLibraries
            $found = $false
            foreach ($lib in $libs) {
                $acf = Join-Path $lib ("appmanifest_" + $ClientChecks.SteamAppId + ".acf")
                if (Test-Path -LiteralPath $acf) { $found = $true; break }
            }
            $client['Installed'] = $found
            $pass = $found
            Write-Log "Steam AppID $($ClientChecks.SteamAppId) installed: $found" ($found ? 'OK' : 'ERROR')
        }
        default {
            $client['Note'] = 'No client validation requested'
            $pass = $true
            Write-Log 'Client validation skipped (none)' 'WARN'
        }
    }
    $Results.Client = $client
    $Results.Summary += @([pscustomobject]@{ Name='Client'; Passed=$pass; Detail='Client presence check' })
}

function Save-Results {
    param($Results)
    $jsonPath = Join-Path $OutDir 'results.json'
    $Results | ConvertTo-Json -Depth 6 | Out-File -FilePath $jsonPath -Encoding UTF8
    Write-Log "Saved results to $jsonPath" 'OK'
}

function Create-SupportBundle {
    param([string]$Directory)
    $zipPath = Join-Path (Split-Path $Directory -Parent) ('support_bundle_' + (Split-Path $Directory -Leaf) + '.zip')
    if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
    $items = @()
    $items += (Join-Path $Directory 'readiness.log')
    $items += (Join-Path $Directory 'results.json')
    $tr = Join-Path $Directory 'tracert.txt'
    if (Test-Path -LiteralPath $tr) { $items += $tr }
    Compress-Archive -Path $items -DestinationPath $zipPath -CompressionLevel Optimal
    Write-Log "Created support bundle: $zipPath" 'OK'
    return $zipPath
}

# Entry
try {
    $OutDir = New-OutputDirectory -RequestedPath $OutDir
    Initialize-Logger -DirectoryPath $OutDir
    $Results = [ordered]@{ Started=(Get-Date -Format o); Summary=@() }
    Write-Log "Output directory: $OutDir" 'OK'

    $defaults = Get-DefaultConfig
    $fileCfg = Load-Config -Path ($ConfigPath ? $ConfigPath : (Join-Path (Get-Location) 'config.json'))
    $merged = Merge-Config -Defaults $defaults -Overrides $fileCfg
    $cfg = Coalesce-Parameters -Config $merged
    $Results.Config = $cfg
    Write-Log ("Effective config: " + ($cfg | ConvertTo-Json -Depth 4)) 'INFO'

    # Prompt for missing essentials so users can run without editing arguments
    if ([string]::IsNullOrWhiteSpace($cfg.ServerHost) -or $cfg.ServerHost -eq 'your.server.example') {
        $inputHost = Read-Host 'Enter server hostname or IP'
        if ([string]::IsNullOrWhiteSpace($inputHost)) {
            Write-Log 'ServerHost is required and was not provided' 'ERROR'
            throw 'Missing ServerHost'
        }
        $cfg.ServerHost = $inputHost.Trim()
        $Results.Config = $cfg
    }
    if (-not $cfg.TcpPorts -or $cfg.TcpPorts.Count -eq 0) {
        $inputPorts = Read-Host 'Enter TCP ports (comma-separated), or press Enter to skip'
        if (-not [string]::IsNullOrWhiteSpace($inputPorts)) {
            $parsed = @()
            foreach ($p in ($inputPorts -split ',')) {
                $pTrim = $p.Trim()
                if ($pTrim -match '^[0-9]+$') { $parsed += [int]$pTrim }
            }
            $cfg.TcpPorts = $parsed
            $Results.Config = $cfg
        } else {
            Write-Log 'No TCP ports provided; continuing without TCP port checks' 'WARN'
        }
    }

    Test-System -Results $Results
    Test-Network -Results $Results -Host $cfg.ServerHost -TcpPorts $cfg.TcpPorts -UdpPorts $cfg.UdpPorts
    Test-Firewall -Results $Results -ExePath $cfg.ClientChecks.ExePath
    Test-Client -Results $Results -ClientChecks $cfg.ClientChecks

    Save-Results -Results $Results
    $zip = Create-SupportBundle -Directory $OutDir

    # Summary output
    Write-Host ''
    Write-Host '==== Readiness Summary ===='
    $passCount = 0; $failCount = 0
    foreach ($item in $Results.Summary) {
        $status = if ($item.Passed) { 'PASS' } else { 'FAIL' }
        if ($item.Passed) { $passCount++ } else { $failCount++ }
        Write-Host ("- {0}: {1} — {2}" -f $item.Name, $status, $item.Detail) -ForegroundColor ($item.Passed ? 'Green' : 'Red')
    }
    Write-Host ("Support bundle: {0}" -f $zip)
    Write-Host ("Log directory: {0}" -f $OutDir)
    if ($failCount -gt 0) { exit 2 } else { exit 0 }
}
catch {
    Write-Log ("Fatal error: $($_.Exception.Message)") 'ERROR'
    Write-Error $_
    exit 1
}


