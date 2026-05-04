<#
.SYNOPSIS
Get failed logins through RDP from Eventlog and add firewall rule to block offending IPs

.DESCRIPTION
He protec
He attac
But most important
He put a block rule against brute-force attac

.INPUTS
None

.OUTPUTS
None

.EXAMPLE
.\ProtectFrom-RDPBruteForce.ps1
Call it from PS commandline

.EXAMPLE
%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -file 'C:\Shares\Scripts\Protect-RDSFromBruteforce\Protect-RDSFromBruteforce.ps1' -FailedLoginCount 10
Call this script from Task Scheduler with FailedLoginCount set to 10 attempts
#>
param (
    # How deep to look in the log, in minutes. Should be reasonably low, to avoid performance impact.
    [ValidateRange(1, 1440)]
    [int]$timePeriod = 60,

    # How many failed logon attempts should be found for a single IP address to be added to the list of offending IPs
    [ValidateRange(1, 100)]
    [int]$FailedLoginCount = 5,

    # Time period, in minutes, after which block rule will be removed
    [ValidateRange(1, 10080)]
    [int]$RemoveBlockRuleAfter = 1440,

    # Full path for HTML report file. Report is generated only if path is given.
    [string]$HTMLReportPath = "c:\_Scripts\BruteForceReport.html"
)

# Dictionary to cache IP-to-country lookups
$IPCountryCache = @{}

function Get-CountryFromIP {
    param (
        [string]$IPAddress
    )

    if ($IPCountryCache.ContainsKey($IPAddress)) {
        return $IPCountryCache[$IPAddress]
    }

    try {
        # Example using a free IP geolocation API
        $url = "http://ip-api.com/json/$IPAddress"
        $response = Invoke-RestMethod -Uri $url -Method Get
        $country = $response.country
        if (-not $country) { $country = "Unknown" }
        $IPCountryCache[$IPAddress] = $country
        return $country
    } catch {
        $IPCountryCache[$IPAddress] = "Unknown"
        return "Unknown"
    }
}

$xpath = @"
<QueryList>
  <Query Id="0" Path="Microsoft-Windows-RemoteDesktopServices-RdpCoreTS/Operational">
    <Select Path="Microsoft-Windows-RemoteDesktopServices-RdpCoreTS/Operational">*[System[(Level=3) and (EventID=140) and TimeCreated[timediff(@SystemTime) &lt;= $($timePeriod * 60 * 1000)]]]</Select>
  </Query>
</QueryList>
"@

$Events = Get-WinEvent -ListLog Microsoft-Windows-RemoteDesktopServices-RdpCoreTS/Operational | Get-WinEvent -FilterXPath $xpath | Select-Object TimeCreated, MachineName, @{N="IP"; E={$_.Properties[0].Value}}

if ($Events) {
    $UniqueIPs = $Events | Select-Object IP -Unique
    $OffendingIPs = foreach ($UniqueIP in $UniqueIPs) {
        $filteredEvents = @($Events | Where-Object { $_.IP -eq $UniqueIP.IP } | Sort-Object -Descending -Property TimeCreated)
        if ($filteredEvents.Count -ge $FailedLoginCount) {
            $country = Get-CountryFromIP -IPAddress $UniqueIP.IP
            [PSCustomObject]@{
                IP              = $UniqueIP.IP
                Country         = $country
                Attempts        = $filteredEvents.Count
                MinutesBetween  = [math]::Round(($filteredEvents[0].TimeCreated - $filteredEvents[$filteredEvents.Count - 1].TimeCreated).TotalMinutes, 0)
                LastAttemptAt   = $filteredEvents[0].TimeCreated
                FirstAttemptAt  = $filteredEvents[$filteredEvents.Count - 1].TimeCreated
            }
        }
    }
}

# Get FW rules for blocking IPs
$dtNow = Get-Date
$NetFWRules = @(Get-NetFirewallRule -DisplayName "RDP-BruteForce-Block") | ForEach-Object {
    $ip = ($_ | Get-NetFirewallAddressFilter).RemoteAddress
    [PSCustomObject]@{
        DateAdded  = [datetime]::Parse($_.Description)
        IP         = $ip
        Country    = if ($ip) { Get-CountryFromIP -IPAddress $ip } else { "Unknown" }
        TimeSpan   = [math]::Round((($dtNow) - ([datetime]::Parse($_.Description))).TotalMinutes, 0)
        Guid       = $_.Name
        Deleted    = [math]::Round((($dtNow) - ([datetime]::Parse($_.Description))).TotalMinutes, 0) -ge $RemoveBlockRuleAfter
    }
}

if ($OffendingIPs) {
    # Generate FW rules
    foreach ($OffendingIP in $OffendingIPs) {
        $Splat = @{
            DisplayName    = "RDP-BruteForce-Block"
            Description    = [datetime]::UtcNow.ToString("o")
            RemoteAddress  = $OffendingIP.IP
        }
        if ($NetFWRules | Where-Object { $_.IP -eq $OffendingIP.IP }) {
            Write-Host "IP $($OffendingIP.IP) already in block list"
        } else {
            New-NetFirewallRule @Splat -Action Block -Direction Inbound -Enabled True -Profile Any
            Write-Host "Added block rule for IP: $($OffendingIP.IP)"
        }
    }
}

# Remove expired FW rules
$NetFWRules | Where-Object { $_.Deleted } | ForEach-Object {
    Remove-NetFirewallRule -Name $_.Guid
    Write-Host "Removed expired rule for IP: $($_.IP)"
}

# Function for generating styled HTML
function Generate-StyledHTML {
    param (
        [string]$Title,
        [string]$Body
    )
    return @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$Title</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            background-color: #f9f9f9;
            color: #333;
        }
        h1 {
            color: #004085;
            border-bottom: 2px solid #ccc;
            padding-bottom: 10px;
        }
        h2 {
            color: #0056b3;
            margin-top: 40px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #007bff;
            color: white;
        }
        tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        tr:hover {
            background-color: #e6f7ff;
        }
        .summary {
            margin-bottom: 20px;
            padding: 6px;
            border: 1px solid #ddd;
            background-color: #fff;
            border-radius: 5px;
        }
        footer {
            margin-top: 40px;
            font-size: 0.9em;
            color: #666;
            text-align: center;
        }
    </style>
</head>
<body>
    <h1>$Title</h1>
    $Body
</body>
</html>
"@
}

# Generate HTML Report Section
if ($HTMLReportPath) {
    $HTMLSummary = @"
<div class='summary'>
    <p><strong>Generated at:</strong> $(Get-Date)</p>
    <p><strong>Time period analyzed:</strong> $(($timePeriod * 60)) seconds</p>
    <p><strong>Failed login attempts threshold:</strong> $FailedLoginCount</p>
    <p><strong>Firewall rule removal time (minutes):</strong> $RemoveBlockRuleAfter</p>
</div>
"@

    $HTMLBody = $HTMLSummary

    if ($OffendingIPs) {
        $HTMLBody += "<h2>Current Offending IPs</h2>"
        $HTMLBody += $OffendingIPs | ConvertTo-Html -Fragment -Property IP, Country, Attempts, MinutesBetween, LastAttemptAt, FirstAttemptAt
    } else {
        $HTMLBody += "<h2>Current Offending IPs</h2><p>No offending IPs found in the log.</p>"
    }

    if ($NetFWRules) {
        $HTMLBody += "<h2>Firewall Rules Block List</h2>"
        $HTMLBody += $NetFWRules | ConvertTo-Html -Fragment -Property DateAdded, TimeSpan, IP, Country, Guid, Deleted
    } else {
        $HTMLBody += "<h2>Firewall Rules Block List</h2><p>No local firewall rules found.</p>"
    }

    $HTMLBody += @"
    <footer>
        <p>&#169; <a href="https://github.com/Barma-lej/tools/tree/main/Protect-RDSFromBruteforce">Barma-lej</a> Generated by RDP Brute-Force Protection Script</p>
    </footer>
</body>
</html>
"@

    if (-not (Test-Path (Split-Path $HTMLReportPath -ErrorAction SilentlyContinue))) {
        New-Item -ItemType Folder -Path (Split-Path $HTMLReportPath) -Force
    }

    $StyledHTML = Generate-StyledHTML -Title "RDP Brute-Force Protection Report" -Body $HTMLBody
    $StyledHTML | Set-Content -Path $HTMLReportPath
    Write-Host "HTML report generated at $HTMLReportPath" -ForegroundColor Green
}
