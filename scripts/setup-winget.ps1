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
    This script validates that the Windows Package Manager (winget) is installed
    on the system. If winget is not installed, the script installs it. If winget
    is already installed, the script checks for updates and applies them. After
    ensuring winget is available and up-to-date, the script imports application
    packages from the winget-apps.json configuration file.

    This script requires administrative privileges to install or update winget and
    to install application packages.

.NOTES
    Author: Richeve Bebedor <richeve.bebedor+vs-scripts@gmail.com>
    Version: 0.0.0
    Last Modified: 2026-02-08
    Platform: Windows only
    Requirements: pwsh 7.5.4 (exact), Administrator privileges

.EXAMPLE
    # Ensures winget is installed, updated, and imports packages
    # from winget-apps.json.
    .\setup-winget.ps1

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
        Downloads and installs the latest version of Windows Package Manager
        (winget) from the Microsoft Store or GitHub releases. This function
        requires administrative privileges.

    .OUTPUTS
        None. Throws an error if installation fails.

    .EXAMPLE
        # Installs winget on the system.
        Install-Winget

    .NOTES
        This function requires administrative privileges and internet
        connectivity.
    #>
    [CmdletBinding()]
    param()

    Write-InfoLog -Scope "WINGET-INSTALL" `
        -Message "Starting winget installation"

    try {
        # Check if running as administrator
        if (-not (Test-IsAdministrator)) {
            throw "Administrative privileges required for installation"
        }

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

        Write-DebugLog -Scope "WINGET-INSTALL" `
            -Message "Stack Trace: $($_.ScriptStackTrace)"

        throw
    }
}

function Update-Winget {
    <#
    .SYNOPSIS
        Updates Windows Package Manager (winget) to the latest version.

    .DESCRIPTION
        Checks for available updates to winget and applies them if
        found. This function requires administrative privileges.

    .OUTPUTS
        None. Throws an error if update fails.

    .EXAMPLE
        # Updates winget to the latest version.
        Update-Winget

    .NOTES
        This function requires administrative privileges and internet
        connectivity.
    #>
    [CmdletBinding()]
    param()

    Write-InfoLog -Scope "WINGET-UPDATE" -Message "Checking for winget updates"

    try {
        # Check if running as administrator
        if (-not (Test-IsAdministrator)) {
            throw "Administrative privileges required for update"
        }

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

        Write-DebugLog -Scope "WINGET-UPDATE" `
            -Message "Stack Trace: $($_.ScriptStackTrace)"

        throw
    }
}

function Assert-WingetAppsJsonExists {
    <#
    .SYNOPSIS
        Validates that winget-apps.json file exists.

    .DESCRIPTION
        Checks if the winget-apps.json configuration file exists in the
        repository root. Throws an error if the file is not found.

    .PARAMETER RepositoryRoot
        The root directory of the repository.

    .OUTPUTS
        System.String. Returns the absolute path to winget-apps.json.

    .EXAMPLE
        # Returns the absolute path to winget-apps.json.
        $jsonPath = Assert-WingetAppsJsonExists -RepositoryRoot $PWD.Path

    .NOTES
        This function throws an error if the file is not found.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RepositoryRoot
    )

    Write-DebugLog -Scope "JSON-VALIDATE" `
        -Message "Validating winget-apps.json existence"

    $jsonPath = Join-Path $RepositoryRoot 'winget-apps.json'
    $absoluteJsonPath = [System.IO.Path]::GetFullPath($jsonPath)

    if (-not (Test-Path -LiteralPath $absoluteJsonPath)) {
        Write-ErrorLog -Scope "JSON-VALIDATE" `
            -Message "File not found: $absoluteJsonPath"

        throw "Required file not found: winget-apps.json"
    }

    Write-InfoLog -Scope "JSON-VALIDATE" `
        -Message "Found winget-apps.json at: $absoluteJsonPath"

    return $absoluteJsonPath
}

function Invoke-WingetImport {
    <#
    .SYNOPSIS
        Imports application packages from winget-apps.json.

    .DESCRIPTION
        Uses winget to import and install application packages defined
        in the winget-apps.json configuration file. This function
        requires administrative privileges.

    .PARAMETER JsonPath
        The absolute path to the winget-apps.json file.

    .OUTPUTS
        None. Throws an error if import fails.

    .EXAMPLE
        # Imports packages from the specified JSON file.
        Invoke-WingetImport -JsonPath "C:\repo\winget-apps.json"

    .NOTES
        This function requires administrative privileges and internet
        connectivity.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$JsonPath
    )

    Write-InfoLog -Scope "WINGET-IMPORT" `
        -Message "Starting package import from: $JsonPath"

    try {
        # Check if running as administrator
        if (-not (Test-IsAdministrator)) {
            throw "Administrative privileges required for package import"
        }

        # Validate JSON path
        if (-not (Test-Path -LiteralPath $JsonPath)) {
            throw "JSON file not found: $JsonPath"
        }

        # Import packages using winget
        Write-InfoLog -Scope "WINGET-IMPORT" `
            -Message "Executing winget import command"

        & winget import `
            -i $JsonPath `
            --accept-source-agreements `
            --accept-package-agreements `
            --disable-interactivity

        if ($LASTEXITCODE -eq 0) {
            Write-InfoLog -Scope "WINGET-IMPORT" `
                -Message "Successfully imported packages"
        }
        else {
            Write-ErrorLog -Scope "WINGET-IMPORT" `
                -Message "Import failed with exit code: $LASTEXITCODE"

            throw "Winget import failed with exit code: $LASTEXITCODE"
        }
    }
    catch {
        Write-ErrorLog -Scope "WINGET-IMPORT" `
            -Message "Failed to import packages: $($_.Exception.Message)"

        Write-DebugLog -Scope "WINGET-IMPORT" `
            -Message "Stack Trace: $($_.ScriptStackTrace)"

        throw
    }
}

function Get-RepositoryRoot {
    <#
    .SYNOPSIS
        Gets the repository root directory.

    .DESCRIPTION
        Determines the repository root directory by checking for git
        repository or falling back to the script directory.

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

    $repositoryRoot = $PWD.Path

    $gitCommand = Get-Command -Name 'git' -ErrorAction SilentlyContinue

    if ($gitCommand) {
        $gitRoot = (& git rev-parse --show-toplevel 2>$null)

        if ($gitRoot -and (Test-Path -LiteralPath $gitRoot)) {
            $repositoryRoot = $gitRoot
        }
    }

    # Fallback to script root if available
    if ($PSScriptRoot -and (Test-Path -LiteralPath $PSScriptRoot)) {
        $parentDirectory = Split-Path -Parent $PSScriptRoot

        if ($parentDirectory -and (Test-Path -LiteralPath $parentDirectory)) {
            $repositoryRoot = $parentDirectory
        }
    }

    Write-InfoLog -Scope "REPO-ROOT" -Message "Repository root: $repositoryRoot"

    return $repositoryRoot
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

    # Get repository root
    $repositoryRoot = Get-RepositoryRoot

    # Check if winget is installed
    $isWingetInstalled = Test-WingetInstalled

    if (-not $isWingetInstalled) {
        Write-InfoLog -Scope "SCRIPT-MAIN" `
            -Message "Winget not found, installing"

        Install-Winget

        # Verify installation
        $isWingetInstalled = Test-WingetInstalled

        if (-not $isWingetInstalled) {
            throw "Winget installation verification failed"
        }
    }
    else {
        Write-InfoLog -Scope "SCRIPT-MAIN" `
            -Message "Winget is already installed, checking for updates"

        Update-Winget
    }

    # Validate winget-apps.json exists
    $jsonPath = Assert-WingetAppsJsonExists `
        -RepositoryRoot $repositoryRoot

    # Import packages from winget-apps.json
    Invoke-WingetImport -JsonPath $jsonPath

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
