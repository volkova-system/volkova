<# :
@echo off
echo.
echo Error: This script must be run from a PowerShell terminal.
echo.
exit /b 1
#>

<#
.SYNOPSIS
    Installs or updates Feather Icons and copies files to destination.

.DESCRIPTION
    This script installs the latest stable version of Feather Icons via npm
    with --save flag. If Feather Icons is already installed, it ensures the
    latest stable version is used. Once installed, it locates the icon files
    and copies them to the specified destination directory within the project
    root. Creates destination directory if needed and replaces existing files.

.PARAMETER DestinationDirectory
    The destination directory path relative to project root where the Feather
    Icons files will be copied. Directory will be created if it does not exist.

.NOTES
    Author: Richeve Bebedor <richeve.bebedor+vs-waste@gmail.com>
    Version: 0.0.0
    Last Modified: 2026-02-15
    Platform: Windows only
    Requirements: pwsh 7.5.4, npm

.EXAMPLE
    # Installs Feather Icons and copies files to assets/icons directory.
    .\setup-feather-icons.ps1 -DestinationDirectory "assets/icons"

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

    Write-WarningLog -Scope "PROJECT-ROOT" `
        -Message "No package.json found in $parentPath"

    throw "Project root with package.json not found"
}

function Assert-NpmAvailable {
    <#
    .SYNOPSIS
        Validates that npm command is available.
    #>
    [CmdletBinding()]
    param()

    $npmCommand = Get-Command -Name 'npm' -ErrorAction SilentlyContinue
    if (-not $npmCommand) {
        Write-WarningLog -Scope "NPM-CHECK" -Message "npm command not found"

        throw "npm command not found"
    }

    Write-InfoLog -Scope "NPM-CHECK" -Message "npm command available"
}

function Install-FeatherIconsPackage {
    <#
    .SYNOPSIS
        Installs or updates Feather Icons package via npm.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    Write-InfoLog -Scope "FEATHER-INSTALL" `
        -Message "Installing latest Feather Icons"

    try {
        & npm install feather-icons@latest --save
        if ($LASTEXITCODE -ne 0) {
            Write-WarningLog -Scope "FEATHER-INSTALL" `
                -Message ("npm install feather-icons@latest --save failed " +
                    "with exit code $LASTEXITCODE")

            throw ("npm install feather-icons@latest --save failed " +
                "with exit code $LASTEXITCODE")
        }

        Write-InfoLog -Scope "FEATHER-INSTALL" `
            -Message "Feather Icons installed successfully"

    } catch {
        throw "Failed to install Feather Icons: $($_.Exception.Message)"
    }
}

function Get-FeatherIconsSpriteFile {
    <#
    .SYNOPSIS
        Locates the Feather Icons SVG sprite file in node_modules.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $featherModulePath = Join-Path $ProjectRoot `
        'node_modules\feather-icons\dist'
    $spriteFile = Join-Path $featherModulePath 'feather-sprite.svg'

    if (-not (Test-Path -LiteralPath $spriteFile)) {
        Write-WarningLog -Scope "FEATHER-LOCATE" `
            -Message "Feather Icons sprite file not found at: $spriteFile"

        throw "Feather Icons sprite file not found at: $spriteFile"
    }

    Write-InfoLog -Scope "FEATHER-LOCATE" -Message "Found sprite file"

    return $spriteFile
}

function Copy-FeatherIconsToDestination {
    <#
    .SYNOPSIS
        Copies Feather Icons minified file to destination directory.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceFile,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )

    if (-not (Test-Path -LiteralPath $DestinationPath)) {
        Write-InfoLog -Scope "DIR-CREATE" `
            -Message "Creating destination directory"

        New-Item -ItemType Directory -Path $DestinationPath -Force | `
            Out-Null
    }

    $destinationFile = Join-Path $DestinationPath 'feather-sprite.svg'

    if (Test-Path -LiteralPath $destinationFile) {
        Write-InfoLog -Scope "FILE-REPLACE" `
            -Message "Replacing existing file"
    }

    Copy-Item -LiteralPath $SourceFile `
        -Destination $destinationFile -Force

    Write-InfoLog -Scope "FEATHER-COPY" `
        -Message "File copied successfully"
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
        Primary workflow implementation for Feather Icons setup.
    #>
    [CmdletBinding()]
    param()

    Write-InfoLog -Scope "SETUP-START" `
        -Message "Starting Feather Icons setup process"

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

    # Install or update Feather Icons
    Install-FeatherIconsPackage -ProjectRoot $projectRoot

    # Locate sprite file
    $featherSpriteFile = Get-FeatherIconsSpriteFile `
        -ProjectRoot $projectRoot

    # Copy to destination
    Copy-FeatherIconsToDestination -SourceFile $featherSpriteFile `
        -DestinationPath $destinationPath

    Write-InfoLog -Scope "SETUP-COMPLETE" `
        -Message "Feather Icons setup completed"
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
        -Message "Failed to setup feathericons: $($_.Exception.Message)"

    Write-DebugLog -Scope "SCRIPT-MAIN" `
        -Message "Stack Trace: $($_.ScriptStackTrace)"

    exit 1
}

#endregion
