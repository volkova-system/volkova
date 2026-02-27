<#
.SYNOPSIS
    Locates the installation path for a WinGet package.

.DESCRIPTION
    Searches Windows Registry for a specified package and returns its
    installation path. Searches HKLM 64-bit and HKLM 32-bit registry
    locations in order. Uses InstallLocation when available.

.NOTES
    Author: WinGet Helper Team
    Version: 1.0.0
    Last Modified: 2026-02-27
    Platform: Windows only
    Requirements: pwsh 7.5.4

.EXIT CODES
    0 - Success
    1 - Failure (with error message)

.EXAMPLE
    Import-Module -Name winget-helper
    Get-WingetInstallPath -PackageName 'Git'
#>

Set-StrictMode -Version Latest

#region Public Functions

function Get-WingetInstallPath {
    <#
    .SYNOPSIS
        Locates the installation path for a WinGet package.

    .DESCRIPTION
        Searches Windows Registry for a specified package and returns its
        installation path. Searches HKLM 64-bit and HKLM 32-bit registry
        locations in order. Uses InstallLocation when available.

    .PARAMETER PackageName
        The name of the package to locate. Supports partial matching.

    .OUTPUTS
        [string] The absolute path to the package installation directory, or $null
        if the package is not found.

    .NOTES
        Author: WinGet Helper Team
        Version: 1.0.0
        Returns $null when not found; logs using concise-log.

    .EXAMPLE
        # Returns: C:\Program Files\Git
        Get-WingetInstallPath -PackageName 'Git'

    .EXAMPLE
        # Returns: $null
        Get-WingetInstallPath -PackageName 'NonExistent'

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PackageName
    )

    $logScope = 'WINGET-HELPER'
    $registryPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    )

    try {
        foreach ($registryPath in $registryPaths) {
            $entries = Get-ItemProperty -LiteralPath $registryPath `
                -ErrorAction SilentlyContinue

            if ($null -eq $entries) {
                continue
            }

            foreach ($entry in $entries) {
                if ($entry.DisplayName -like "*$PackageName*") {
                    $installLocation = $entry.InstallLocation
                    if ($null -ne $installLocation) {
                        if (Test-Path -LiteralPath $installLocation) {
                            $absolutePath = Resolve-Path `
                                -LiteralPath $installLocation

                            $resolvedPath = $absolutePath.Path

                            Write-InfoLog `
                                -Scope $logScope `
                                -Message ("Package '$PackageName' found at " +
                                    "'$resolvedPath'")

                            return $resolvedPath
                        }
                    }
                }
            }
        }

        Write-WarningLog `
            -Scope $logScope `
            -Message "Package '$PackageName' not found in any registry location"

        return $null
    }
    catch {
        Write-ErrorLog `
            -Scope $logScope `
            -Message "Error searching for package '$PackageName': $_"

        return $null
    }
}

#endregion

#region Private Functions

#endregion

# Export public functions
Export-ModuleMember -Function @('Get-WingetInstallPath')
