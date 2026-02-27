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
    Requires: PowerShell 7.4 LTS+, concise-log module

.EXAMPLE
    Import-Module -Name winget-helper
    Get-WingetInstallPath -PackageName 'Git'
#>

Set-StrictMode -Version Latest

# Import concise-log module for logging
Import-Module -Name concise-log -ErrorAction Stop

#region Public Functions

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
    System.String
    The absolute path to the package installation directory, or $null
    if the package is not found.

.EXAMPLE
    Get-WingetInstallPath -PackageName 'Git'
    Returns: C:\Program Files\Git

.EXAMPLE
    Get-WingetInstallPath -PackageName 'NonExistent'
    Returns: $null
#>
function Get-WingetInstallPath {
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
            $entries = Get-ItemProperty -Path $registryPath `
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
                            Write-Log -Scope $logScope `
                                -Level Information `
                                -Message "Package '$PackageName' found at " `
                                "'$resolvedPath'"
                            return $resolvedPath
                        }
                    }
                }
            }
        }

        Write-Log -Scope $logScope -Level Warning `
            -Message "Package '$PackageName' not found in any " `
            "registry location"
        return $null
    }
    catch {
        Write-Log -Scope $logScope -Level Error `
            -Message "Error searching for package '$PackageName': $_"
        return $null
    }
}

#endregion

#region Private Functions

#endregion

# Export public functions
Export-ModuleMember -Function @('Get-WingetInstallPath')
