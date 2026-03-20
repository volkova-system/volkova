<#
.SYNOPSIS
    Locates the installation path for a WinGet package.

.DESCRIPTION
    Searches Windows Registry for a specified package and returns its
    installation path. Searches HKLM 64-bit, HKLM 32-bit, and HKCU
    locations in order. Uses InstallLocation when available.

.NOTES
    Author: WinGet Helper Team
    Version: 1.0.0
    Last Modified: 2026-02-27
    Platform: Windows only
    Requirements: pwsh 7.6.0
    Dependencies: concise-log.psm1

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
        installation path. Searches HKLM 64-bit, HKLM 32-bit, and HKCU
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
            $registrySubkeys = Get-ChildItem `
                -LiteralPath $registryPath `
                -ErrorAction SilentlyContinue

            if ($null -eq $registrySubkeys) {
                continue
            }

            foreach ($registrySubkey in $registrySubkeys) {
                $registryEntry = Get-ItemProperty `
                    -LiteralPath $registrySubkey.PSPath `
                    -ErrorAction SilentlyContinue

                if ($null -eq $registryEntry) {
                    continue
                }

                if (-not ($registryEntry.PSObject.Properties.Name `
                    -contains 'DisplayName')) {
                    continue
                }
                $displayName = $registryEntry.DisplayName

                if ($displayName -like "*$PackageName*") {
                    $pathCandidates = @()

                    if ($registryEntry.PSObject.Properties.Name `
                        -contains 'InstallLocation') {
                        $pathCandidates += $registryEntry.InstallLocation
                    }
                    if ($registryEntry.PSObject.Properties.Name `
                        -contains 'InstallDir') {
                        $pathCandidates += $registryEntry.InstallDir
                    }
                    if ($registryEntry.PSObject.Properties.Name `
                        -contains 'InstallPath') {
                        $pathCandidates += $registryEntry.InstallPath
                    }
                    if ($registryEntry.PSObject.Properties.Name `
                        -contains 'InstallFolder') {
                        $pathCandidates += $registryEntry.InstallFolder
                    }

                    if ($registryEntry.PSObject.Properties.Name `
                        -contains 'DisplayIcon') {
                        $displayIcon = $registryEntry.DisplayIcon
                        $displayIconString = $displayIcon.ToString().Trim()
                        $displayIconPath = $displayIconString

                        if ($displayIconString.StartsWith('"')) {
                            $matchResult = [regex]::Match(
                                $displayIconString, '^"([^"]+)"'
                            )
                            if ($matchResult.Success) {
                                $displayIconPath = $matchResult.Groups[1].Value
                            }
                        } else {
                            $displayIconPath = ($displayIconString -split '\s+')[0]
                        }

                        $displayIconPath = ($displayIconPath -split ',')[0]

                        if ($displayIconPath) {
                            $pathCandidates += $displayIconPath
                        }
                    }

                    if ($registryEntry.PSObject.Properties.Name `
                        -contains 'UninstallString') {
                        $uninstallString = $registryEntry.UninstallString
                        $uninstallStringValue = $uninstallString.ToString().Trim()
                        if ($uninstallStringValue -and ($uninstallStringValue `
                            -notmatch '(?i)\\msiexec(\.exe)?\b')) {
                            $executablePath = $uninstallStringValue

                            if ($uninstallStringValue.StartsWith('"')) {
                                $matchResult = [regex]::Match(
                                    $uninstallStringValue, '^"([^"]+)"'
                                )
                                if ($matchResult.Success) {
                                    $executablePath = $matchResult.Groups[1].Value
                                }
                            } else {
                                $executablePath = (
                                    $uninstallStringValue -split '\s+'
                                )[0]
                            }

                            $executablePath = ($executablePath -split ',')[0]
                            if ($executablePath) {
                                $pathCandidates += $executablePath
                            }
                        }
                    }

                    foreach ($candidatePath in $pathCandidates) {
                        if ($null -eq $candidatePath) { continue }
                        $candidatePathTrimmed = $candidatePath.ToString().Trim()

                        if (-not $candidatePathTrimmed) { continue }

                        if (Test-Path -LiteralPath $candidatePathTrimmed) {
                            $resolvedItem = $null
                            try {
                                $resolvedItem = (
                                    Get-Item `
                                        -LiteralPath $candidatePathTrimmed `
                                        -ErrorAction SilentlyContinue
                                )
                            } catch {}

                            $resolvedDirectory = $candidatePathTrimmed
                            if ($resolvedItem -and `
                                -not $resolvedItem.PSIsContainer) {
                                $resolvedDirectory = (
                                    [System.IO.Path]::GetDirectoryName(
                                        $candidatePathTrimmed
                                    )
                                )
                            }
                            if ($resolvedDirectory -and (
                                Test-Path -LiteralPath $resolvedDirectory `
                                -PathType Container
                            )) {
                                $absolutePath = (
                                    [System.IO.Path]::GetFullPath(
                                        $resolvedDirectory
                                    )
                                )
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
