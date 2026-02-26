<# :
@echo off
echo.
echo Error: This script must be run from a PowerShell terminal.
echo.
exit /b 1
#>

<#
.SYNOPSIS
    Ensures winget is installed and imports application packages.

.DESCRIPTION
    Ensures winget is installed and up-to-date.

    If missing, installs App Installer (winget); otherwise applies updates.

    Validates winget-apps.json, updates package versions to the latest, and imports
    packages non-interactively with required agreements.

    Requires administrative privileges.

    See helps/powershell-core-module-format.help for core function specifications.

.NOTES
    Author: Richeve Bebedor <richeve.bebedor963+vs-scripts@proton.me>
    Version: 0.0.0
    Last Modified: 2026-02-26
    Platform: Windows only
    Requirements: pwsh 7.5.4 (exact), Administrator privileges

.EXAMPLE
    # Ensures winget is installed, updates versions in winget-apps.json, and
    # imports packages.
    .\scripts\setup-winget.ps1

.EXIT CODES
    0 - Success
    1 - Failure (with error message)
#>

[CmdletBinding()]
param()

#region Module Import

# Import required modules
$scriptPath = $PSScriptRoot
$conciseLogPath = Join-Path $scriptPath 'concise-log.psm1'
$coreModulePath = Join-Path $scriptPath 'powershell-core.psm1'

# Convert to absolute paths (REQUIRED)
$conciseLogPath = [System.IO.Path]::GetFullPath($conciseLogPath)
$coreModulePath = [System.IO.Path]::GetFullPath($coreModulePath)

if (-not (Test-Path -LiteralPath $conciseLogPath)) {
    Write-Error 'Required module not found: concise-log.psm1'
    exit 1
}

if (-not (Test-Path -LiteralPath $coreModulePath)) {
    Write-Error 'Required module not found: powershell-core.psm1'
    exit 1
}

Import-Module -Name $conciseLogPath -Force -ErrorAction Stop
Import-Module -Name $coreModulePath -Force -ErrorAction Stop

#endregion

#region Core Functions

function Test-WingetInstalled {
    <#
    .SYNOPSIS
        Tests if winget is installed on the system.

    .DESCRIPTION
        Checks if the Windows Package Manager (winget) command is available in the
        system PATH. Returns true if winget is installed and accessible,
        false otherwise.

    .OUTPUTS
        System.Boolean. Returns $true if winget is installed, $false otherwise.

    .EXAMPLE
        if (Test-WingetInstalled) {
            Write-InfoLog -Scope "WINGET-CHECK" -Message "Winget is installed"
        }

    .NOTES
        This function uses Get-Command to check for winget availability.

    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    Write-DebugLog -Scope "WINGET-CHECK" -Message "Checking if winget is installed"

    $wingetCommand = Get-Command -Name 'winget' -ErrorAction SilentlyContinue

    if ($wingetCommand) {
        Write-InfoLog -Scope "WINGET-CHECK" `
            -Message "Winget is installed at: $($wingetCommand.Source)"

        return $true
    }

    Write-WarningLog -Scope "WINGET-CHECK" -Message "Winget is not installed"

    return $false
}

function Install-Winget {
    <#
    .SYNOPSIS
        Installs Windows Package Manager (winget).

    .DESCRIPTION
        Downloads and installs App Installer (which includes winget) using the
        Microsoft Store distribution (aka.ms/getwinget). Requires administrative
        privileges.

    .OUTPUTS
        None. Throws an error if installation fails.

    .EXAMPLE
        Install-Winget

    .NOTES
        Downloads to a temporary path, installs via Add-AppxPackage, and removes
        the installer file after installation.
    #>
    [CmdletBinding()]
    param()

    Write-InfoLog -Scope "WINGET-INSTALL" -Message "Starting winget installation"

    try {
        # Install App Installer package which includes winget
        $packageName = "Microsoft.DesktopAppInstaller"

        Write-InfoLog -Scope "WINGET-INSTALL" `
            -Message "Installing package: $packageName"

        # Use Add-AppxPackage to install from Microsoft Store
        $storePackageUrl = "https://aka.ms/getwinget"

        Write-DebugLog -Scope "WINGET-INSTALL" `
            -Message "Downloading from: $storePackageUrl"

        # Download the package
        $temporaryPath = [System.IO.Path]::GetTempPath()
        $packagePath = Join-Path $temporaryPath "winget-installer.msixbundle"

        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($storePackageUrl, $packagePath)
        $webClient.Dispose()

        Write-InfoLog -Scope "WINGET-INSTALL" `
            -Message "Downloaded installer to: $packagePath"

        # Install the package
        Add-AppxPackage -Path $packagePath -ErrorAction Stop

        Write-InfoLog -Scope "WINGET-INSTALL" `
            -Message "Successfully installed winget"

        # Clean up temporary file
        if (Test-Path -LiteralPath $packagePath) {
            Remove-Item -LiteralPath $packagePath -Force
        }
    }
    catch {
        Write-ErrorLog -Scope "WINGET-INSTALL" `
            -Message "Failed to install winget: $($_.Exception.Message)"

        throw
    }
}

function Update-Winget {
    <#
    .SYNOPSIS
        Updates Windows Package Manager (winget) to the latest version.

    .DESCRIPTION
        Checks for available updates and applies them using winget upgrade with
        non-interactive and agreement flags. Handles benign exit codes when no
        update is required.

    .OUTPUTS
        None. Throws an error if update fails.

    .EXAMPLE
        Update-Winget

    .NOTES
        Requires winget to be installed.
    #>
    [CmdletBinding()]
    param()

    Write-InfoLog -Scope "WINGET-UPDATE" -Message "Checking for winget updates"

    try {
        # Update winget using winget itself
        & winget upgrade `
            --id Microsoft.Winget.Source `
            --accept-source-agreements `
            --disable-interactivity

        $benignExitCodes = @(-1978335212, -1978335189)
        if ($LASTEXITCODE -eq 0) {
            Write-InfoLog -Scope "WINGET-UPDATE" `
                -Message "Successfully updated winget"
        }
        elseif ($LASTEXITCODE -in $benignExitCodes) {
            Write-InfoLog -Scope "WINGET-UPDATE" `
                -Message ("No update needed or source not applicable " +
                    "(exit $LASTEXITCODE)")
        }
        else {
            Write-WarningLog -Scope "WINGET-UPDATE" `
                -Message "Winget update returned code: $LASTEXITCODE"
        }
    }
    catch {
        Write-ErrorLog -Scope "WINGET-UPDATE" `
            -Message "Failed to update winget: $($_.Exception.Message)"

        throw
    }
}

function Get-RepositoryRoot {
    <#
    .SYNOPSIS
        Gets the repository root directory.

    .DESCRIPTION
        Determines the repository root directory by checking for git repository.

    .OUTPUTS
        System.String. Returns the absolute path to the repository root.

    .EXAMPLE
        # Returns the repository root directory path.
        $repoRoot = Get-RepositoryRoot

    .NOTES
        This function attempts to use git to find the repository root.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    Write-DebugLog -Scope "REPO-ROOT" `
        -Message "Determining repository root directory"

    $gitCommand = Get-Command -Name 'git' -ErrorAction SilentlyContinue

    if (-not $gitCommand) {
        Write-ErrorLog -Scope "REPO-ROOT" -Message "Git not found in PATH"

        throw "Git is required to determine repository root"
    }

    $gitRoot = (& git rev-parse --show-toplevel 2>$null)

    if (-not $gitRoot) {
        Write-ErrorLog -Scope "REPO-ROOT" `
            -Message "Git repository root could not be determined"

        throw "Git repository root not found"
    }

    $absoluteRoot = [System.IO.Path]::GetFullPath($gitRoot)

    if (-not (Test-Path -LiteralPath $absoluteRoot)) {
        Write-ErrorLog -Scope "REPO-ROOT" `
            -Message "Repository root path invalid: $absoluteRoot"

        throw "Invalid repository root path"
    }

    Write-InfoLog -Scope "REPO-ROOT" `
        -Message "Repository root: $absoluteRoot"

    return $absoluteRoot
}

function Test-RepositoryRoot {
    <#
    .SYNOPSIS
        Tests if the repository root directory exists.

    .DESCRIPTION
        Determines the repository root directory by calling Get-RepositoryRoot and
        verifies its existence on the filesystem. Returns true if the repository
        root is determined and exists, false otherwise.

    .OUTPUTS
        System.Boolean. Returns $true if the repository root exists, $false
        otherwise.

    .EXAMPLE
        if (Test-RepositoryRoot) {
            Write-InfoLog -Scope "REPO-TEST" -Message "Repository root is valid"
        }

    .NOTES
        This function handles exceptions from Get-RepositoryRoot by logging the
        error and returning $false.

    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    Write-DebugLog -Scope "REPO-TEST" -Message "Testing repository root existence"

    try {
        $repositoryRoot = Get-RepositoryRoot

        if (Test-Path -LiteralPath $repositoryRoot -PathType Container) {
            return $true
        }

        return $false
    }
    catch {
        Write-ErrorLog -Scope "REPO-TEST" `
            -Message "Failed to test repository root: $($_.Exception.Message)"

        return $false
    }
}

function Get-WingetAppsJsonPath {
    <#
    .SYNOPSIS
        Returns the absolute path to winget-apps.json.

    .DESCRIPTION
        Resolves the repository root using Get-RepositoryRoot and constructs
        the absolute file path to winget-apps.json. This function does not
        validate file existence; use Test-WingetAppsJsonExists to verify.

    .OUTPUTS
        System.String. Returns the absolute path to winget-apps.json.

    .EXAMPLE
        $jsonPath = Get-WingetAppsJsonPath
        Retrieves the absolute path to winget-apps.json.

    .NOTES
        winget-apps.json is expected to reside at the repository root.

    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    Write-DebugLog -Scope "JSON-PATH" `
        -Message "Resolving winget-apps.json absolute path"

    $repositoryRoot = Get-RepositoryRoot
    $wingetAppsJsonPath = Join-Path $repositoryRoot 'winget-apps.json'
    $wingetAppsJsonPath = [System.IO.Path]::GetFullPath($wingetAppsJsonPath)

    Write-InfoLog -Scope "JSON-PATH" `
        -Message "winget-apps.json path: $wingetAppsJsonPath"

    return $wingetAppsJsonPath
}

function Test-WingetAppsJsonExists {
    <#
    .SYNOPSIS
        Tests if winget-apps.json exists at the resolved absolute path.

    .DESCRIPTION
        Resolves the absolute path to winget-apps.json using
        Get-WingetAppsJsonPath and tests whether the file exists. Returns
        true if the file exists, false otherwise.

    .OUTPUTS
        System.Boolean. Returns $true if winget-apps.json exists, $false otherwise.

    .EXAMPLE
        if (Test-WingetAppsJsonExists) {
            Write-InfoLog -Scope "JSON-VALIDATE" -Message "winget-apps.json found"
        }

    .NOTES
        Use before updating versions or importing packages.

    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    Write-DebugLog -Scope "JSON-VALIDATE" `
        -Message "Validating winget-apps.json existence"

    try {
        $repositoryRoot = Get-RepositoryRoot
        $wingetAppsJsonPath = Join-Path $repositoryRoot 'winget-apps.json'
        $wingetAppsJsonPath = [System.IO.Path]::GetFullPath($wingetAppsJsonPath)

        return (Test-Path -LiteralPath $wingetAppsJsonPath -PathType Leaf)
    }
    catch {
        Write-ErrorLog -Scope "JSON-VALIDATE" `
            -Message "winget-apps.json check failed: $($_.Exception.Message)"

        return $false
    }
}

function Update-WingetAppsJsonVersions {
    <#
    .SYNOPSIS
        Updates package Version fields in winget-apps.json to latest available.

    .DESCRIPTION
        Reads the winget-apps.json configuration, queries winget for the latest
        available version for each PackageIdentifier, and updates the Version
        field accordingly. Writes changes back to the same JSON file.

    .OUTPUTS
        None. Throws an error if update fails.

    .NOTES
        Resolves the file path via Get-WingetAppsJsonPath.

    .EXAMPLE
        # Updates the JSON file with latest package versions.
        Update-WingetAppsJsonVersions

    #>
    [CmdletBinding()]
    param()

    Write-InfoLog -Scope "JSON-UPDATE" -Message "Updating package versions"

    try {
        $wingetAppsJsonPath = Get-WingetAppsJsonPath
        $wingetAppsJsonContent = Get-Content -LiteralPath $wingetAppsJsonPath -Raw
        $configuration = $wingetAppsJsonContent | ConvertFrom-Json

        if (-not $configuration) {
            throw "Invalid JSON format in $wingetAppsJsonPath"
        }

        if(-not $configuration.Sources -or $configuration.Sources.Count -eq 0) {
            throw "No sources defined in $wingetAppsJsonPath"
        }

        foreach ($packageSource in $configuration.Sources) {
            $packages = $packageSource.Packages

            if (-not $packages -or $packages.Count -eq 0) {
                Write-ErrorLog -Scope "JSON-UPDATE" -Message "No packages defined"

                throw "No packages defined"
            }

            foreach ($package in $packages) {
                $packageIdentifier = $package.PackageIdentifier

                if (-not $packageIdentifier) {
                    Write-ErrorLog -Scope "JSON-UPDATE" `
                        -Message "Package entry missing PackageIdentifier"

                    throw "Invalid package entry: missing PackageIdentifier"
                }

                $latestVersion = $null

                $showOutput = & winget show `
                    --id $packageIdentifier `
                    --disable-interactivity

                if ($LASTEXITCODE -eq 0 -and $showOutput) {
                    $versionLine = ($showOutput -split "`r`n") |
                        Where-Object { $_ -match '^\s*Version\s*:\s*(\S+)' } |
                        Select-Object -First 1

                    if ($versionLine) {
                        $latestVersion = [regex]::Match($versionLine,
                            '^\s*Version\s*:\s*(\S+)'
                        ).Groups[1].Value

                    } else {
                        throw ("Stable version not reported for " +
                            "$packageIdentifier")
                    }
                } else {
                    throw ("Get stable version failed for " +
                        "$packageIdentifier (exit $LASTEXITCODE)")
                }

                if ($latestVersion) {
                    if ($package.Version -ne $latestVersion) {
                        Write-InfoLog -Scope "JSON-UPDATE" `
                            -Message ("Updating $packageIdentifier " +
                                "$($package.Version) -> $latestVersion")

                        $package.Version = $latestVersion
                    }
                    else {
                        Write-InfoLog -Scope "JSON-UPDATE" `
                            -Message "No change for $packageIdentifier"
                    }
                }
                else {
                    Write-WarningLog -Scope "JSON-UPDATE" `
                        -Message "Version unresolved for $packageIdentifier"
                }
            }
        }

        $updatedJson = $configuration | ConvertTo-Json -Depth 10
        $updatedJson = (($updatedJson -split '\r?\n') |
            ForEach-Object {
                $match = [regex]::Match($_, '^( +)')
                if ($match.Success) {
                    $leading = $match.Groups[1].Value.Length
                    $level = [math]::Floor($leading / 2)
                    (' ' * (4 * $level)) + $_.TrimStart()
                }
                else { $_ }
            }) -join "`r`n"

        Set-Content `
            -LiteralPath $wingetAppsJsonPath `
            -Value $updatedJson `
            -Encoding UTF8

        Write-InfoLog -Scope "JSON-UPDATE" `
            -Message "Update completed: $($packages.Count) packages resolved"
    }
    catch {
        Write-ErrorLog -Scope "JSON-UPDATE" `
            -Message "Update failed: $($_.Exception.Message)"

        throw
    }
}

function Invoke-WingetImport {
    <#
    .SYNOPSIS
        Imports application packages from winget-apps.json.

    .DESCRIPTION
        Uses winget to import, install, and update application packages defined in
        winget-apps.json. Automatically resolves the file path via
        Get-WingetAppsJsonPath.

    .OUTPUTS
        None. Throws an error if import fails.

    .EXAMPLE
        Invoke-WingetImport

    .NOTES
        Uses agreement and non-interactive flags; requires administrative
        privileges.
    #>
    [CmdletBinding()]
    param()

    Write-InfoLog -Scope "WINGET-IMPORT" `
        -Message "Starting package import from: $JsonPath"

    try {
        $wingetAppsJsonPath = Get-WingetAppsJsonPath

        # Import packages using winget
        Write-InfoLog -Scope "WINGET-IMPORT" `
            -Message "Executing winget import command"

        & winget import `
            -i $wingetAppsJsonPath `
            --accept-source-agreements `
            --accept-package-agreements `
            --disable-interactivity

        if ($LASTEXITCODE -eq 0) {
            Write-InfoLog -Scope "WINGET-IMPORT" `
                -Message "Successfully imported packages"
        }
        else {
            throw "Winget import failed with exit code: $LASTEXITCODE"
        }
    }
    catch {
        Write-ErrorLog -Scope "WINGET-IMPORT" `
            -Message "Failed to import packages: $($_.Exception.Message)"

        throw
    }
}

#endregion

#region Main Script Execution

Initialize-ScriptEnvironment
$null = Test-IsInteractivePowerShell
Invoke-PowerShellCoreTransition
Assert-WindowsPlatform
Assert-PowerShellVersionStrict

# Check for elevation (REQUIRED for elevated scripts)
if (-not (Test-IsAdministrator)) {
    Invoke-ElevationRequest -ScriptPath $PSCommandPath
}

try {
    Write-InfoLog -Scope "SCRIPT-MAIN" `
        -Message "Starting winget setup process"

    if (-not $(Test-RepositoryRoot)) {
        Write-ErrorLog -Scope "REPO-TEST" -Message "Repository root not found"

        throw "Repository root not found"
    }

    if (-not $(Test-WingetInstalled)) {
        Write-InfoLog -Scope "SCRIPT-MAIN" -Message "Winget not found, installing"

        Install-Winget

        if (-not $(Test-WingetInstalled)) {
            throw "Winget installation verification failed"
        }
    }
    else {
        Write-InfoLog -Scope "SCRIPT-MAIN" `
            -Message "Winget is already installed, checking for updates"

        Update-Winget
    }

    # Validate winget-apps.json exists
    if (-not $(Test-WingetAppsJsonExists)) {
        throw "Required file not found: winget-apps.json"
    }

    # Update package versions in winget-apps.json
    Update-WingetAppsJsonVersions

    # Import packages from winget-apps.json
    Invoke-WingetImport

    Write-InfoLog -Scope "SCRIPT-MAIN" `
        -Message "Success: Winget setup completed successfully"

    exit 0
}
catch {
    Write-ErrorLog -Scope "SCRIPT-MAIN" `
        -Message "Operation failed: $($_.Exception.Message)"

    Write-DebugLog -Scope "SCRIPT-MAIN" `
        -Message "Stack Trace: $($_.ScriptStackTrace)"

    exit 1
}

#endregion
