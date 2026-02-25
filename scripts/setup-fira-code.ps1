<# :
@echo off
echo.
echo Error: This script must be run from a PowerShell terminal.
echo.
exit /b 1
#>

<#
.SYNOPSIS
    Installs or updates Fira Code and copies font file to destination.

.DESCRIPTION
    This script installs the latest stable version of Fira Code via npm
    with --save flag. If Fira Code is already installed, it ensures the
    latest stable version is used. Once installed, it locates the
    FiraCode-Regular.woff2 file and copies it to the specified
    destination directory within the project root. Creates destination
    directory if needed and replaces existing files.

.PARAMETER DestinationDirectory
    The destination directory path relative to project root where the
    Fira Code font file will be copied. Directory will be created if
    it does not exist.

.NOTES
    Author: Richeve Bebedor <richeve.bebedor+vs-scripts@gmail.com>
    Version: 0.0.0
    Last Modified: 2026-02-17
    Platform: Windows only
    Requirements: pwsh 7.5.4, npm

.EXAMPLE
    # Installs Fira Code and copies font file to assets/fonts directory.
    .\setup-fira-code.ps1 -DestinationDirectory "assets/fonts"

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

function Install-FiraCodePackage {
    <#
    .SYNOPSIS
        Installs or updates Fira Code package via npm.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    Write-InfoLog -Scope "FIRACODE-INSTALL" `
        -Message "Installing latest Fira Code"

    try {
        & npm install firacode@latest --save
        if ($LASTEXITCODE -ne 0) {
            Write-WarningLog -Scope "FIRACODE-INSTALL" `
                -Message ("npm install firacode@latest --save failed " +
                    "with exit code $LASTEXITCODE")

            throw ("npm install firacode@latest --save failed " +
                "with exit code $LASTEXITCODE")
        }

        Write-InfoLog -Scope "FIRACODE-INSTALL" `
            -Message "Fira Code installed successfully"

    } catch {
        throw "Failed to install Fira Code: $($_.Exception.Message)"
    }
}

function Get-FiraCodeFontFile {
    <#
    .SYNOPSIS
        Locates the FiraCode-Regular.woff2 file in node_modules.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $firaCodeModulePath = Join-Path $ProjectRoot `
        'node_modules\firacode\distr\woff2'
    $fontFile = Join-Path $firaCodeModulePath 'FiraCode-Regular.woff2'

    if (-not (Test-Path -LiteralPath $fontFile)) {
        Write-WarningLog -Scope "FIRACODE-LOCATE" `
            -Message "FiraCode-Regular.woff2 not found at: $fontFile"

        throw "FiraCode-Regular.woff2 not found at: $fontFile"
    }

    Write-InfoLog -Scope "FIRACODE-LOCATE" -Message "Found font file"

    return $fontFile
}

function Copy-FiraCodeToDestination {
    <#
    .SYNOPSIS
        Copies Fira Code font file to destination directory.
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

    $destinationFile = Join-Path $DestinationPath 'FiraCode-Regular.woff2'

    if (Test-Path -LiteralPath $destinationFile) {
        Write-InfoLog -Scope "FILE-REPLACE" `
            -Message "Replacing existing file"
    }

    Copy-Item -LiteralPath $SourceFile `
        -Destination $destinationFile -Force

    Write-InfoLog -Scope "FIRACODE-COPY" `
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
        Primary workflow implementation for Fira Code setup.
    #>
    [CmdletBinding()]
    param()

    Write-InfoLog -Scope "SETUP-START" `
        -Message "Starting Fira Code setup process"

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

    # Install or update Fira Code
    Install-FiraCodePackage -ProjectRoot $projectRoot

    # Locate font file
    $firaCodeFontFile = Get-FiraCodeFontFile `
        -ProjectRoot $projectRoot

    # Copy to destination
    Copy-FiraCodeToDestination -SourceFile $firaCodeFontFile `
        -DestinationPath $destinationPath

    Write-InfoLog -Scope "SETUP-COMPLETE" `
        -Message "Fira Code setup completed"
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
        -Message "Failed to setup firacode: $($_.Exception.Message)"

    Write-DebugLog -Scope "SCRIPT-MAIN" `
        -Message "Stack Trace: $($_.ScriptStackTrace)"

    exit 1
}

#endregion
