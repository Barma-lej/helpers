# Base application installation via WinGet.
# Run Windows PowerShell as Administrator.
# Requires internet access and WinGet (App Installer).

$ErrorActionPreference = 'Continue'

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error 'WinGet was not found. Install App Installer from Microsoft Store and run again.'
    exit 1
}

$packages = @(
    @{ Id = 'RARLab.WinRAR';               Name = 'WinRAR (German)'; Locale = 'de-DE' },
    @{ Id = 'Google.Chrome';               Name = 'Google Chrome' },
    @{ Id = 'Adobe.Acrobat.Reader.64-bit'; Name = 'Adobe Acrobat Reader' },
    @{ Id = 'AnyDesk.AnyDesk';             Name = 'AnyDesk' }

    # Optional applications: remove # at the beginning to enable.
#    @{ Id = '7zip.7zip';                  Name = '7-Zip' },
#    @{ Id = 'VideoLAN.VLC';               Name = 'VLC media player' },
#    @{ Id = 'Notepad++.Notepad++';        Name = 'Notepad++' }
)

$installedCount = 0
$skippedCount = 0
$failedCount = 0

foreach ($package in $packages) {
    Write-Host ''
    Write-Host "Checking: $($package.Name)" -ForegroundColor Yellow

    # Exit code 0 means winget found an installed package with this exact ID.
    & winget list --id $package.Id --exact --source winget --accept-source-agreements 2>$null
    $isInstalled = ($LASTEXITCODE -eq 0)

    if ($isInstalled) {
        Write-Host "Already installed: $($package.Name)" -ForegroundColor Green
        $skippedCount++
        continue
    }

    Write-Host "Installing: $($package.Name)" -ForegroundColor Cyan

    $wingetArgs = @(
        'install',
        '--id', $package.Id,
        '--exact',
        '--source', 'winget',
        '--silent',
        '--accept-package-agreements',
        '--accept-source-agreements'
    )

    if ($package.Locale) {
        $wingetArgs += @('--locale', $package.Locale)
    }

    & winget @wingetArgs

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Installed: $($package.Name)" -ForegroundColor Green
        $installedCount++
    } else {
        Write-Warning "Installation failed: $($package.Name). Exit code: $LASTEXITCODE"
        $failedCount++
    }
}

Write-Host ''
Write-Host '========== Summary ==========' -ForegroundColor White
Write-Host "Installed: $installedCount" -ForegroundColor Green
Write-Host "Already installed: $skippedCount" -ForegroundColor Yellow
Write-Host "Failed: $failedCount" -ForegroundColor Red
Write-Host 'Restart the computer if an installer requested it.' -ForegroundColor Green