<# :
@echo off
echo.
echo Error: This script must be run from a PowerShell terminal.
echo.
exit /b 1
#>

<#
.SYNOPSIS
    Installs or updates HTMX and copies minified file to destination.

.DESCRIPTION
    This script installs the latest stable version of HTMX via npm with
    --save flag. If HTMX is already installed, it ensures the latest
    stable version is used. Once installed, it locates the minified
    file and copies it to the specified destination directory within
    the project root. Creates destination directory if needed and
    replaces existing files.

.PARAMETER DestinationDirectory
    The destination directory path relative to project root where the
    HTMX minified file will be copied. Directory will be created if
    it does not exist.

.NOTES
    Author: Richeve Bebedor <richeve.bebedor+vs-waste@gmail.com>
    Version: 0.0.0
    Last Modified: 2026-02-05
    Platform: Windows only
    Requirements: pwsh 7.5.4, npm

.EXAMPLE
    # Installs HTMX and copies minified file to assets/js directory.
    .\setup-htmx.ps1 -DestinationDirectory "assets/js"

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

function Install-HtmxPackage {
    <#
    .SYNOPSIS
        Installs or updates HTMX package via npm.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    Write-InfoLog -Scope "HTMX-INSTALL" -Message "Installing latest HTMX"

    try {
        & npm install htmx.org@latest --save
        if ($LASTEXITCODE -ne 0) {
            Write-WarningLog -Scope "HTMX-INSTALL" `
                -Message ("npm install htmx.org@latest --save failed " +
                    "with exit code $LASTEXITCODE")

            throw "npm install htmx.org --save failed with exit code $LASTEXITCODE"
        }

        Write-InfoLog -Scope "HTMX-INSTALL" -Message "HTMX installed successfully"

    } catch {
        throw "Failed to install HTMX: $($_.Exception.Message)"
    }
}

function Get-HtmxMinifiedFile {
    <#
    .SYNOPSIS
        Locates the HTMX minified file in node_modules.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $htmxModulePath = Join-Path $ProjectRoot 'node_modules\htmx.org\dist'
    $minifiedFile = Join-Path $htmxModulePath 'htmx.min.js'

    if (-not (Test-Path -LiteralPath $minifiedFile)) {
        Write-WarningLog -Scope "HTMX-LOCATE" `
            -Message "HTMX minified file not found at: $minifiedFile"

        throw "HTMX minified file not found at: $minifiedFile"
    }

    Write-InfoLog -Scope "HTMX-LOCATE" -Message "Found minified file"

    return $minifiedFile
}

function Copy-HtmxToDestination {
    <#
    .SYNOPSIS
        Copies HTMX minified file to destination directory.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceFile,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )

    if (-not (Test-Path -LiteralPath $DestinationPath)) {
        Write-InfoLog -Scope "DIR-CREATE" -Message "Creating destination directory"

        New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
    }

    $destinationFile = Join-Path $DestinationPath 'htmx.min.js'

    if (Test-Path -LiteralPath $destinationFile) {
        Write-InfoLog -Scope "FILE-REPLACE" -Message "Replacing existing file"
    }

    Copy-Item -LiteralPath $SourceFile -Destination $destinationFile -Force

    Write-InfoLog -Scope "HTMX-COPY" -Message "File copied successfully"
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
    $resolvedDestination = [System.IO.Path]::GetFullPath($fullDestinationPath)
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
        Primary workflow implementation for HTMX setup.
    #>
    [CmdletBinding()]
    param()

    Write-InfoLog -Scope "SETUP-START" -Message "Starting HTMX setup process"

    # Get project root and validate destination
    $projectRoot = Get-ProjectRoot
    $destinationPath = Test-DestinationPath -ProjectRoot $projectRoot `
        -DestinationDirectory $DestinationDirectory

    Write-InfoLog -Scope "PROJECT-ROOT" -Message "Project root: $projectRoot"
    Write-InfoLog -Scope "DEST-PATH" -Message "Destination: $destinationPath"

    # Validate npm availability
    Assert-NpmAvailable

    # Install or update HTMX
    Install-HtmxPackage -ProjectRoot $projectRoot

    # Locate minified file
    $htmxMinFile = Get-HtmxMinifiedFile -ProjectRoot $projectRoot

    # Copy to destination
    Copy-HtmxToDestination -SourceFile $htmxMinFile `
        -DestinationPath $destinationPath

    Write-InfoLog -Scope "SETUP-COMPLETE" -Message "HTMX setup completed"
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
        -Message "Failed to setup htmx: $($_.Exception.Message)"

    Write-DebugLog -Scope "SCRIPT-MAIN" `
        -Message "Stack Trace: $($_.ScriptStackTrace)"

    exit 1
}

#endregion
