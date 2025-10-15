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
        Write-Log "Failed to parse config at $($Path): $($_.Exception.Message)" 'WARN'
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

function Convert-ToIntArray {
    param($Value)
    if ($null -eq $Value) { return @() }
    if ($Value -is [array]) {
        $out = @()
        foreach ($v in $Value) { try { $out += [int]$v } catch {} }
        return $out
    }
    try { return @([int]$Value) } catch { return @() }
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
    param([string]$TargetHost)
    try {
        if (Get-Command Resolve-DnsName -ErrorAction SilentlyContinue) {
            $r = Resolve-DnsName -Name $TargetHost -ErrorAction Stop
            return $r.IPAddress | Select-Object -Unique
        } else {
            return [System.Net.Dns]::GetHostAddresses($TargetHost).IPAddressToString
        }
    } catch { return @() }
}

function Test-Network {
    param($Results, [string]$TargetHost, [int[]]$TcpPorts, [int[]]$UdpPorts)
    Write-Log 'Running network checks...'
    $net = [ordered]@{}
    # Check if TargetHost is already an IP address
    $isIp = $false
    try { $null = [System.Net.IPAddress]::Parse($TargetHost); $isIp = $true } catch {}
    if ($isIp) {
        $net['DnsResolved'] = @($TargetHost)
        Write-Log "Using IP address directly: $TargetHost" 'OK'
    } else {
        $ips = Resolve-Host -TargetHost $TargetHost
        $net['DnsResolved'] = @($ips)
        $ipCount = 0
        if ($null -ne $ips) { $ipCount = @($ips).Count }
        if ($ipCount -gt 0) { Write-Log "DNS resolved $TargetHost => $($ips -join ', ')" 'OK' } else { Write-Log "DNS failed for $TargetHost" 'ERROR' }
    }

    try {
        # PS 5.1 uses -ComputerName, PS 7+ uses -TargetName
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            $pings = Test-Connection -TargetName $TargetHost -Count 4 -Quiet:$false -ErrorAction Stop
        } else {
            $pings = Test-Connection -ComputerName $TargetHost -Count 4 -Quiet:$false -ErrorAction Stop
        }
        $stats = $pings | Measure-Object -Property ResponseTime -Average -Minimum -Maximum
        $lat = [pscustomobject]@{ MinMs=$stats.Minimum; AvgMs=[math]::Round($stats.Average,2); MaxMs=$stats.Maximum }
        $net['Ping'] = $lat
        Write-Log "Ping latency ms: min=$($lat.MinMs) avg=$($lat.AvgMs) max=$($lat.MaxMs)" 'OK'
    } catch { Write-Log "Ping failed: $($_.Exception.Message)" 'WARN' }

    $tcpResults = @()
    foreach ($port in $TcpPorts) {
        try {
            $tnc = Test-NetConnection -ComputerName $TargetHost -Port $port -WarningAction SilentlyContinue
            $ok = $false
            if ($tnc -and ($tnc.TcpTestSucceeded -eq $true)) { $ok = $true }
            $tcpResults += [pscustomobject]@{ Port=$port; Reachable=$ok }
            if ($ok) { Write-Log "TCP $port => $ok" 'OK' } else { Write-Log "TCP $port => $ok" 'ERROR' }
        } catch {
            $tcpResults += [pscustomobject]@{ Port=$port; Reachable=$false }
            Write-Log "TCP test error on $($port): $($_.Exception.Message)" 'ERROR'
        }
    }
    $net['TcpPorts'] = $tcpResults

    $udpResults = @()
    foreach ($port in $UdpPorts) {
        $udpOk = $false
        try {
            $client = New-Object System.Net.Sockets.UdpClient
            $client.Client.ReceiveTimeout = 500
            $client.Connect($TargetHost, $port)
            $bytes = [Text.Encoding]::ASCII.GetBytes('probe')
            [void]$client.Send($bytes, $bytes.Length)
            $udpOk = $true
            $client.Close()
        } catch { $udpOk = $false }
        $udpResults += [pscustomobject]@{ Port=$port; SentProbe=$udpOk; Note='UDP is stateless; result advisory' }
        if ($udpOk) { Write-Log "UDP $port probe sent=$udpOk (advisory)" 'OK' } else { Write-Log "UDP $port probe sent=$udpOk (advisory)" 'WARN' }
    }
    $net['UdpPorts'] = $udpResults

    try {
        $trPath = Join-Path $OutDir 'tracert.txt'
        tracert -d -h 15 $TargetHost | Out-File -FilePath $trPath -Encoding UTF8
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
        if ($ghOk) { Write-Log "GitHub reachability: $ghOk" 'OK' } else { Write-Log "GitHub reachability: $ghOk" 'WARN' }
    } catch { Write-Log "GitHub reachability check failed: $($_.Exception.Message)" 'WARN' }

    $Results.Network = $net
    $tcpFails = @($tcpResults | Where-Object { $_.Reachable -eq $false })
    $tcpPass = (@($tcpFails).Count -eq 0)
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
            $ruleCount = 0
            if ($null -ne $rules) { $ruleCount = @($rules).Count }
            Write-Log "Found $ruleCount firewall rule(s) for exe" 'OK'
        } catch { Write-Log "Firewall rule query failed: $($_.Exception.Message)" 'WARN' }
    }
    $Results.Firewall = $fw
    $Results.Summary += @([pscustomobject]@{ Name='Firewall'; Passed=$true; Detail='Collected firewall profiles and rules' })
}

function Read-SteamLibraries {
    $libs = @()
    try {
        $steamRoot = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam' -Name InstallPath -ErrorAction Stop).InstallPath
        if (-not [string]::IsNullOrWhiteSpace($steamRoot)) {
            $libs += (Join-Path $steamRoot 'steamapps')
        }
    } catch {}
    try {
        $steamRootCU = (Get-ItemProperty -Path 'HKCU:\SOFTWARE\Valve\Steam' -Name SteamPath -ErrorAction Stop).SteamPath
        if (-not [string]::IsNullOrWhiteSpace($steamRootCU)) {
            $libs += (Join-Path $steamRootCU 'steamapps')
        }
    } catch {}
    $libs = @($libs | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
    # Parse libraryfolders.vdf for additional libraries
    foreach ($root in $libs) {
        if ([string]::IsNullOrWhiteSpace($root)) { continue }
        $parentPath = Split-Path $root -Parent
        if ([string]::IsNullOrWhiteSpace($parentPath)) { continue }
        $vdf = Join-Path $parentPath 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf -ErrorAction SilentlyContinue) {
            try {
                $content = Get-Content -LiteralPath $vdf -Raw -ErrorAction Stop
                $matches = [regex]::Matches($content, '"path"\s*"([^"]+)"')
                foreach ($m in $matches) {
                    $path = $m.Groups[1].Value
                    if (-not [string]::IsNullOrWhiteSpace($path)) {
                        $libs += (Join-Path $path 'steamapps')
                    }
                }
            } catch {}
        }
    }
    return @($libs | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
}

function Find-AssettoCorsa {
    $libs = Read-SteamLibraries
    foreach ($lib in $libs) {
        if ([string]::IsNullOrWhiteSpace($lib)) { continue }
        $acPath = Join-Path (Split-Path $lib -Parent) 'common\assettocorsa'
        $acsExe = Join-Path $acPath 'acs.exe'
        if ((Test-Path $acsExe -ErrorAction SilentlyContinue)) { return $acPath }
    }
    return $null
}

function Get-CSPVersion {
    param([string]$ACPath)
    if ([string]::IsNullOrWhiteSpace($ACPath)) { return $null }
    $dllPath = Join-Path $ACPath 'extension\dwrite.dll'
    if (-not (Test-Path $dllPath -ErrorAction SilentlyContinue)) { return $null }
    try {
        $ver = (Get-Item $dllPath -ErrorAction Stop).VersionInfo.FileVersion
        if ($ver) { return $ver }
    } catch {}
    return 'installed'
}

function Test-ACContent {
    param($Results)
    Write-Log 'Running Assetto Corsa content checks...'
    $content = [ordered]@{}
    $pass = $true
    
    $acPath = Find-AssettoCorsa
    $content['ACInstalled'] = ($null -ne $acPath)
    if ($acPath) {
        Write-Log "Assetto Corsa found: $acPath" 'OK'
        $content['ACPath'] = $acPath
        
        $cspVer = Get-CSPVersion -ACPath $acPath
        $content['CSPInstalled'] = ($null -ne $cspVer)
        $content['CSPVersion'] = $cspVer
        if ($cspVer) {
            Write-Log "CSP installed: $cspVer" 'OK'
        } else {
            Write-Log "CSP NOT installed (required 0.1.76+)" 'ERROR'
            $pass = $false
        }
        
        $tracksPath = Join-Path $acPath 'content\tracks'
        $trackPath = Join-Path $tracksPath 'shuto_revival_project_beta'
        $layoutPath = Join-Path $trackPath 'heiwajima_pa_n'
        $content['TrackInstalled'] = (Test-Path $trackPath -ErrorAction SilentlyContinue)
        $content['LayoutInstalled'] = (Test-Path $layoutPath -ErrorAction SilentlyContinue)
        if (Test-Path $layoutPath -ErrorAction SilentlyContinue) {
            Write-Log "Track installed: Shuto Revival Project Beta - Heiwajima PA (North)" 'OK'
        } else {
            Write-Log "Track MISSING: Shuto Revival Project Beta" 'ERROR'
            $pass = $false
        }
        
        $carsPath = Join-Path $acPath 'content\cars'
        $requiredCars = @('abarth500','alfa_romeo_giulietta_qv','bmw_1m_s3','bmw_m3_e30','bmw_m3_e92_s1','ferrari_458','ferrari_458_s3','ferrari_f40_s3','ferrari_laferrari','ks_alfa_giulia_qv','ks_alfa_mito_qv','ks_audi_a1s1','ks_audi_r8_plus','ks_corvette_c7_stingray','ks_ford_mustang_2015','ks_lamborghini_huracan_performante','ks_lamborghini_sesto_elemento','ks_maserati_alfieri','ks_maserati_quattroporte','ks_mazda_miata','ks_mercedes_190_evo2','ks_nissan_gtr','ks_porsche_911_gt3_rs_2016','ks_porsche_cayman_gt4_std','ks_toyota_ae86_tuned','ks_toyota_supra_mkiv','lotus_exige_scura','lotus_exige_v6_cup','mazda_rx7_spirit_r','nissan_370z','supra_a90')
        $missingCars = @()
        foreach ($car in $requiredCars) {
            $carPath = Join-Path $carsPath $car
            if (-not (Test-Path $carPath -ErrorAction SilentlyContinue)) { $missingCars += $car }
        }
        $content['TotalCars'] = $requiredCars.Count
        $content['InstalledCars'] = $requiredCars.Count - $missingCars.Count
        $content['MissingCars'] = $missingCars
        if ($missingCars.Count -eq 0) {
            Write-Log "All $($requiredCars.Count) required cars installed" 'OK'
        } else {
            Write-Log "$($missingCars.Count) cars MISSING: $($missingCars -join ', ')" 'WARN'
        }
    } else {
        Write-Log "Assetto Corsa NOT installed" 'ERROR'
        $content['TotalCars'] = 0
        $content['InstalledCars'] = 0
        $content['MissingCars'] = @()
        $pass = $false
    }
    
    $Results.Content = $content
    $detailMsg = if ($content['ACInstalled']) { "AC+CSP+Track+Cars ($($content.InstalledCars)/$($content.TotalCars) cars)" } else { "Assetto Corsa not found" }
    $Results.Summary += @([pscustomobject]@{ Name='Content'; Passed=$pass; Detail=$detailMsg })
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
    $fileCfg = $null
    if ($ConfigPath) {
        $fileCfg = Load-Config -Path $ConfigPath
    } else {
        $fileCfg = Load-Config -Path (Join-Path (Get-Location) 'config.json')
    }
    $merged = Merge-Config -Defaults $defaults -Overrides $fileCfg
    $cfg = Coalesce-Parameters -Config $merged
    # Normalize ports to arrays to support single-value inputs
    $cfg.TcpPorts = Convert-ToIntArray -Value $cfg.TcpPorts
    $cfg.UdpPorts = Convert-ToIntArray -Value $cfg.UdpPorts
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
    if (-not $cfg.TcpPorts -or @($cfg.TcpPorts).Count -eq 0) {
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
    Test-Network -Results $Results -TargetHost $cfg.ServerHost -TcpPorts $cfg.TcpPorts -UdpPorts $cfg.UdpPorts
    Test-Firewall -Results $Results -ExePath $cfg.ClientChecks.ExePath
    Test-ACContent -Results $Results

    Save-Results -Results $Results
    $zip = Create-SupportBundle -Directory $OutDir

    # Summary output
    Write-Host ''
    Write-Host '==== Readiness Summary ===='
    $passCount = 0; $failCount = 0
    foreach ($item in $Results.Summary) {
        $status = if ($item.Passed) { 'PASS' } else { 'FAIL' }
        if ($item.Passed) { $passCount++ } else { $failCount++ }
        $fg = 'Red'
        if ($item.Passed) { $fg = 'Green' }
        Write-Host ("- {0}: {1} - {2}" -f $item.Name, $status, $item.Detail) -ForegroundColor $fg
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


