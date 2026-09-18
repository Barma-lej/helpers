# Remove optional preinstalled Microsoft/OEM Appx applications.
# Run Windows PowerShell as Administrator.
# This script first shows all matches and requires confirmation.

$ErrorActionPreference = 'Continue'

$patterns = @(
    '*Dropbox*',
    '*DropboxOEM*',

    '*Cortana*',
    'Microsoft.549981C3F5F10',
    'Microsoft.People',

    '*BingNews*',
    '*BingSearch*',
    '*BingWeather*',

    '*Family*',
    '*GetHelp*',
    '*Getstarted*',
    '*MicrosoftOfficeHub*',
#    '*MicrosoftSolitaireCollection*',
    '*MixedReality.Portal*',
#    '*People*',
    '*PowerAutomateDesktop*',
    '*SkypeApp*',
#    '*Spades*',
    '*Todos*',
#    '*WindowsAlarms*',
    '*WindowsFeedbackHub*',
    '*WindowsMaps*',
    '*YourPhone*',
    '*ZuneMusic*',
    '*ZuneVideo*',

#    '*Clipchamp*',
#    '*MicrosoftTeams*',
#    '*MSTeams*',

    # Xbox / Xbox Live
    '*GamingApp*',
    '*XboxApp*',
    '*XboxGameOverlay*',
    '*XboxGamingOverlay*',
    '*XboxIdentityProvider*',
    '*XboxSpeechToTextOverlay*',
    '*Xbox.TCUI*'
)

function Test-Match {
    param(
        [string]$Value,
        [string[]]$Patterns
    )

    foreach ($pattern in $Patterns) {
        if ($Value -like $pattern) {
            return $true
        }
    }

    return $false
}

# Installed Appx packages for all existing user profiles.
$installedApps = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue |
    Where-Object {
        (Test-Match $_.Name $patterns) -or
        (Test-Match $_.PackageFullName $patterns)
    } |
    Sort-Object Name, PackageFullName -Unique

# Provisioned packages: prevent installation for newly created user profiles.
$provisionedApps = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
    Where-Object {
        (Test-Match $_.DisplayName $patterns) -or
        (Test-Match $_.PackageName $patterns)
    } |
    Sort-Object DisplayName, PackageName -Unique

if (-not $installedApps -and -not $provisionedApps) {
    Write-Warning 'No matching optional Microsoft/OEM Appx packages were found.'
    exit 0
}

Write-Host ''
Write-Host 'Installed Appx packages to remove:' -ForegroundColor Yellow

if ($installedApps) {
    $installedApps |
        Select-Object Name, PackageFullName, NonRemovable |
        Format-Table -AutoSize
} else {
    Write-Host 'None'
}

Write-Host ''
Write-Host 'Provisioned packages to remove for future users:' -ForegroundColor Yellow

if ($provisionedApps) {
    $provisionedApps |
        Select-Object DisplayName, PackageName |
        Format-Table -AutoSize
} else {
    Write-Host 'None'
}

Write-Host ''
Write-Host 'These applications will be removed after confirmation.' -ForegroundColor Red
$answer = Read-Host 'Continue? Type YES'

if ($answer -cne 'YES') {
    Write-Host 'Cancelled. Nothing was removed.' -ForegroundColor Yellow
    exit 0
}

Write-Host ''
Write-Host 'Removing installed Appx packages...' -ForegroundColor Cyan

foreach ($app in $installedApps) {
    Write-Host "Removing: $($app.Name)" -ForegroundColor Cyan

    try {
        Remove-AppxPackage -Package $app.PackageFullName -AllUsers -ErrorAction Stop
        Write-Host '  Removed.' -ForegroundColor Green
    } catch {
        Write-Warning "  Could not remove $($app.Name): $($_.Exception.Message)"
    }
}

Write-Host ''
Write-Host 'Removing provisioned packages...' -ForegroundColor Cyan

foreach ($app in $provisionedApps) {
    Write-Host "Removing provisioning: $($app.DisplayName)" -ForegroundColor Cyan

    try {
        Remove-AppxProvisionedPackage -Online -PackageName $app.PackageName -AllUsers -ErrorAction Stop |
            Out-Null
        Write-Host '  Provisioning removed.' -ForegroundColor Green
    } catch {
        Write-Warning "  Could not remove provisioning for $($app.DisplayName): $($_.Exception.Message)"
    }
}

Write-Host ''
Write-Host 'Done. Restart the computer.' -ForegroundColor Green