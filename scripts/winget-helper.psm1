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
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    )

    try {
        foreach ($registryPath in $registryPaths) {
            $subkeys = Get-ChildItem -LiteralPath $registryPath `
                -ErrorAction SilentlyContinue

            if ($null -eq $subkeys) {
                continue
            }

            foreach ($subkey in $subkeys) {
                $entry = Get-ItemProperty -LiteralPath $subkey.PSPath `
                    -ErrorAction SilentlyContinue

                if ($null -eq $entry) {
                    continue
                }

                if (-not ($entry.PSObject.Properties.Name -contains 'DisplayName')) {
                    continue
                }
                $displayName = $entry.DisplayName

                if ($displayName -like "*$PackageName*") {
                    $candidates = @()

                    if ($entry.PSObject.Properties.Name -contains 'InstallLocation') {
                        $candidates += $entry.InstallLocation
                    }
                    if ($entry.PSObject.Properties.Name -contains 'InstallDir') {
                        $candidates += $entry.InstallDir
                    }
                    if ($entry.PSObject.Properties.Name -contains 'InstallPath') {
                        $candidates += $entry.InstallPath
                    }
                    if ($entry.PSObject.Properties.Name -contains 'InstallFolder') {
                        $candidates += $entry.InstallFolder
                    }

                    if ($entry.PSObject.Properties.Name -contains 'DisplayIcon') {
                        $displayIcon = $entry.DisplayIcon
                        $iconStr = $displayIcon.ToString().Trim()
                        $iconPath = $iconStr
                        if ($iconStr.StartsWith('"')) {
                            $m = [regex]::Match($iconStr, '^"([^"]+)"')
                            if ($m.Success) { $iconPath = $m.Groups[1].Value }
                        }
                        else {
                            $iconPath = ($iconStr -split '\s+')[0]
                        }
                        $iconPath = ($iconPath -split ',')[0]
                        if ($iconPath) {
                            $candidates += $iconPath
                        }
                    }

                    if ($entry.PSObject.Properties.Name -contains 'UninstallString') {
                        $uninstallString = $entry.UninstallString
                        $uStr = $uninstallString.ToString().Trim()
                        if ($uStr -and ($uStr -notmatch '(?i)\\msiexec(\.exe)?\b')) {
                            $exePath = $uStr
                            if ($uStr.StartsWith('"')) {
                                $m = [regex]::Match($uStr, '^"([^"]+)"')
                                if ($m.Success) { $exePath = $m.Groups[1].Value }
                            }
                            else {
                                $exePath = ($uStr -split '\s+')[0]
                            }
                            $exePath = ($exePath -split ',')[0]
                            if ($exePath) {
                                $candidates += $exePath
                            }
                        }
                    }

                    foreach ($candidate in $candidates) {
                        if ($null -eq $candidate) { continue }
                        $cand = $candidate.ToString().Trim()
                        if (-not $cand) { continue }

                        if (Test-Path -LiteralPath $cand) {
                            $item = $null
                            try { $item = Get-Item -LiteralPath $cand -ErrorAction SilentlyContinue } catch {}
                            $dir = $cand
                            if ($item -and -not $item.PSIsContainer) {
                                $dir = [System.IO.Path]::GetDirectoryName($cand)
                            }
                            if ($dir -and (Test-Path -LiteralPath $dir -PathType Container)) {
                                $absolutePath = [System.IO.Path]::GetFullPath($dir)
                                Write-InfoLog `
                                    -Scope $logScope `
                                    -Message ("Package '$PackageName' found at " +
                                        "'$absolutePath'")
                                return $absolutePath
                            }
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
