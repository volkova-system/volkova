<# :
@echo off
echo.
echo Error: This script must be run from a PowerShell terminal.
echo.
exit /b 1
#>

<#
.SYNOPSIS
    Installs or updates Simple Icons and copies files to destination.

.DESCRIPTION
    This script installs the latest stable version of Simple Icons via npm
    with --save flag. If Simple Icons is already installed, it ensures the
    latest stable version is used. Once installed, it locates the icon files
    and copies them to the specified destination directory within the project
    root. Creates destination directory if needed and replaces existing files.

.PARAMETER DestinationDirectory
    The destination directory path relative to project root where the Simple
    Icons files will be copied. Directory will be created if it does not exist.

.NOTES
    Author: Richeve Bebedor <richeve.bebedor+vs-waste@gmail.com>
    Version: 0.0.0
    Last Modified: 2026-03-03
    Platform: Windows only
    Requirements: pwsh 7.5.5, npm

.EXAMPLE
    # Installs Simple Icons and copies files to assets/icons directory.
    .\setup-simple-icons.ps1 -DestinationDirectory "assets/icons"

.EXIT CODES
    0 - Success
    1 - Failure (with error message)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true,
        HelpMessage = "Destination directory path")]
    [ValidateNotNullOrEmpty()]
    [string]$DestinationDirectory
)

Set-StrictMode -Version Latest

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

#region Primary Functions

function Get-ProjectRoot {
    <#
    .SYNOPSIS
        Gets the project root directory containing package.json.
    #>
    [CmdletBinding()]
    param()

    [string]$currentPath = $PSScriptRoot
    [string]$parentPath = Split-Path -Path $currentPath -Parent

    $packageJsonPath = Join-Path $parentPath 'package.json'
    if (Test-Path -LiteralPath $packageJsonPath) {
        return $parentPath
    }

    Write-WarningLog -Scope "PROJECT-ROOT
K" -Message "npm command available"
}

function Install-SimpleIconsPackage {
    <#
    .SYNOPSIS
        Installs or updates Simple Icons package via npm.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    Write-InfoLog -Scope "SIMPLE-INSTALL" `
        -Message "Installing latest Simple Icons"

    try {
        & npm install simple-icons@latest --save
        if ($LASTEXITCODE -ne 0) {
            Write-WarningLog -Scope "SIMPLE-INSTALL" `
                -Message ("npm install simple-icons@latest --save failed " +
                    "with exit code $LASTEXITCODE")

            throw ("npm install simple-icons@latest --save failed " +
                "with exit code $LASTEXITCODE")
        }

        Write-InfoLog -Scope "SIMPLE-INSTALL" `
            -Message "Simple Icons installed successfully"

    } catch {
        throw "Failed to install Simple Icons: $($_.Exception.Message)"
    }
}

function Get-SimpleIconsDirectory {
    <#
    .SYNOPSIS
        Locates the Simple Icons directory in node_modules.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $simpleIconsPath = Join-Path $ProjectRoot `
        'node_modules\simple-icons\icons'

    if (-not (Test-Path -LiteralPath $simpleIconsPath)) {
        Write-WarningLog -Scope "SIMPLE-LOCATE" `
            -Message "Simple Icons directory not found at: $simpleIconsPath"

        throw "Simple Icons directory not found at: $simpleIconsPath"
    }

    Write-InfoLog -Scope "SIMPLE-LOCATE" -Message "Found icons directory"

    return $simpleIconsPath
}

function Copy-SimpleIconsToDestination {
    <#
    .SYNOPSIS
        Copies Simple Icons files to destination directory.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceDirectory,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )

    if (-not (Test-Path -LiteralPath $DestinationPath)) {
        Write-InfoLog -Scope "DIR-CREATE" `
            -Message "Creating destination directory"

        New-Item -ItemType Directory -Path $DestinationPath -Force | `
            Out-Null
    }

    $iconFiles = Get-ChildItem -LiteralPath $SourceDirectory `
        -Filter '*.svg' -File

    if ($iconFiles.Count -eq 0) {
        Write-WarningLog -Scope "SIMPLE-COPY" `
            -Message "No SVG files found in source directory"

        throw "No SVG files found in source directory"
    }

    Write-InfoLog -Scope "SIMPLE-COPY" `
        -Message "Copying $($iconFiles.Count) icon files"

    foreach ($iconFile in $iconFiles) {
        $destinationFile = Join-Path $DestinationPath $iconFile.Name

        Copy-Item -LiteralPath $iconFile.FullName `
            -Destination $destinationFile -Force
    }

    Write-InfoLog -Scope "SIMPLE-COPY" `
        -Message "Files copied successfully"
}

function Test-DestinationPath {
    <#
    .SYNOPSIS
        Validates destination directory is within project root.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$DestinationDirectory
    )

    $fullDestinationPath = Join-Path $ProjectRoot $DestinationDirectory
    $resolvedDestination = [System.IO.Path]::GetFullPath(
        $fullDestinationPath
    )
    $resolvedProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)

    if (-not $resolvedDestination.StartsWith($resolvedProjectRoot)) {
        Write-WarningLog -Scope "DEST-CHECK" `
            -Message "Destination must be within project root directory"

        throw "Destination must be within project root directory"
    }

    return $resolvedDestination
}

function Invoke-PrimaryWorkflow {
    <#
    .SYNOPSIS
        Primary workflow implementation for Simple Icons setup.
    #>
    [CmdletBinding()]
    param()

    Write-InfoLog -Scope "SETUP-START" `
        -Message "Starting Simple Icons setup process"

    # Get project root and validate destination
    $projectRoot = Get-ProjectRoot
    $destinationPath = Test-DestinationPath -ProjectRoot $projectRoot `
        -DestinationDirectory $DestinationDirectory

    Write-InfoLog -Scope "PROJECT-ROOT" `
        -Message "Project root: $projectRoot"
    Write-InfoLog -Scope "DEST-PATH" `
        -Message "Destination: $destinationPath"

    # Validate npm availability
    Assert-NpmAvailable

    # Install or update Simple Icons
    Install-SimpleIconsPackage -ProjectRoot $projectRoot

    # Locate icons directory
    $simpleIconsDirectory = Get-SimpleIconsDirectory `
        -ProjectRoot $projectRoot

    # Copy to destination
    Copy-SimpleIconsToDestination -SourceDirectory $simpleIconsDirectory `
        -DestinationPath $destinationPath

    Write-InfoLog -Scope "SETUP-COMPLETE" `
        -Message "Simple Icons setup completed"
}

#endregion

#region Main Script Execution

Initialize-ScriptEnvironment
Assert-WindowsPlatform
Assert-PowerShellVersionStrict

try {
    Invoke-PrimaryWorkflow

    exit 0
} catch {
    Write-ErrorLog -Scope "SCRIPT-MAIN" `
        -Message "Failed to setup simpleicons: $($_.Exception.Message)"

    Write-DebugLog -Scope "SCRIPT-MAIN" `
        -Message "Stack Trace: $($_.ScriptStackTrace)"

    exit 1
}

#endregion
