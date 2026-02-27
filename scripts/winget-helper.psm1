function Get-WingetInstallPath {

    param(
        [Parameter(Mandatory=$true)]
        [string]$PackageName
    )

    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $registryPaths) {

        $apps = Get-ItemProperty $path -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.DisplayName -like "*$PackageName*"
                }

        foreach ($app in $apps) {

            # Preferred: InstallLocation
            if ($app.InstallLocation -and (Test-Path $app.InstallLocation)) {
                return (Resolve-Path $app.InstallLocation).Path
            }

            # Fallback: Parse UninstallString
            if ($app.UninstallString) {

                $match = [regex]::Match($app.UninstallString, '"([^"]+)"')

                if ($match.Success) {
                    $exePath = $match.Groups[1].Value

                    if (Test-Path $exePath) {
                        return (Split-Path $exePath -Parent)
                    }
                }
            }
        }
    }

    return $null
}
