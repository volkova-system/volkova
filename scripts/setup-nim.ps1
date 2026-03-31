<# :
@echo off
echo.
echo Error: This script must be run from a PowerShell terminal.
echo.
exit /b 1
#>

<#
.SYNOPSIS
    Installs the stable version of Nim using choosenim.

.DESCRIPTION
    Verifies that choosenim is installed via winget (NimLang.ChooseNim).
    If choosenim is not found, the script throws an error and exits.
    Installs the latest stable version of Nim via choosenim, then
    registers the Nim ecosystem binaries (nimble bin directory) in the
    Machine-level PATH environment variable so that nim, nimble, and
    related tools are available to all users via pwsh 7.6.0.

    Requires administrative privileges to update the Machine PATH.

    See helps/powershell-core-module-format.help for core function
    specifications.

.NOTES
    Author: Richeve Bebedor <richeve.bebedor+vs-scripts@gmail.com>
    Version: 0.0.0
    Last Modified: 2026-03-31
    Platform: Windows only
    Requirements: pwsh 7.6.0 (exact), Administrator privileges
    Dependencies: choosenim (NimLang.ChooseNim via winget)

.EXAMPLE
    .\scripts\setup-nim.ps1
    Installs stable Nim and registers nim ecosystem paths system-wide.

.EXIT CODES
    0 - Success
    1 - Failure (with error message)
#>

[CmdletBinding()]
param()

#region Module Import

$scriptPath = $PSScriptRoot
$conciseLogPath = Join-Path $scriptPath 'concise-log.psm1'
$coreModulePath = Join-Path $scriptPath 'powershell-core.psm1'

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

#region Validation Functions

function Assert-ChoosenimInstalled {
    <#
    .SYNOPSIS
        Asserts that choosenim is available in the current PATH.

    .DESCRIPTION
        Checks whether the choosenim executable is resolvable via
        Get-Command. If choosenim is not found, logs an error and
        throws an exception to halt script execution. choosenim must
        be installed via winget (NimLang.ChooseNim) before running
        this script.

    .OUTPUTS
        None. Throws if choosenim is not found.

    .EXAMPLE
        Assert-ChoosenimInstalled

    .NOTES
        No fallback or alternative detection is attempted.
    #>
    [CmdletBinding()]
    param()

    Write-DebugLog -Scope "NIM-CHECK" `
        -Message "Checking for choosenim in PATH"

    $choosenimCommand = Get-Command `
        -Name 'choosenim' `
        -ErrorAction SilentlyContinue

    if (-not $choosenimCommand) {
        Write-ErrorLog -Scope "NIM-CHECK" `
            -Message ("choosenim not found. " +
                "Install via winget: winget install NimLang.ChooseNim")

        throw "choosenim is not installed or not in PATH"
    }

    Write-InfoLog -Scope "NIM-CHECK" `
        -Message "choosenim found at: $($choosenimCommand.Source)"
}

#endregion

#region Installation Functions

function Invoke-NimStableInstallation {
    <#
    .SYNOPSIS
        Installs the latest stable version of Nim via choosenim.

    .DESCRIPTION
        Invokes choosenim with the 'stable' channel argument to install
        the latest stable Nim release. choosenim manages the download,
        extraction, and local toolchain setup automatically.

    .OUTPUTS
        None. Throws if the choosenim invocation fails.

    .EXAMPLE
        Invoke-NimStableInstallation

    .NOTES
        choosenim exits with a non-zero code on failure.
        The --noColor flag is used for clean log output.
    #>
    [CmdletBinding()]
    param()

    Write-InfoLog -Scope "NIM-INSTALL" `
        -Message "Installing stable Nim via choosenim"

    & choosenim stable --noColor

    if ($LASTEXITCODE -ne 0) {
        Write-ErrorLog -Scope "NIM-INSTALL" `
            -Message "choosenim exited with code: $LASTEXITCODE"

        throw ("choosenim failed to install stable Nim " +
            "(exit $LASTEXITCODE)")
    }

    Write-InfoLog -Scope "NIM-INSTALL" `
        -Message "choosenim completed stable Nim installation"
}

#endregion

#region Path Functions

function Get-NimbleBinDirectory {
    <#
    .SYNOPSIS
        Returns the absolute path to the nimble bin directory.

    .DESCRIPTION
        Constructs the path to the nimble bin directory under the current
        user profile. choosenim places nim, nimble, and all related
        ecosystem binaries in this directory after installation.

    .OUTPUTS
        System.String. Absolute path to the nimble bin directory.

    .EXAMPLE
        $nimbleBinDirectory = Get-NimbleBinDirectory

    .NOTES
        The nimble bin directory is always at %USERPROFILE%\.nimble\bin
        regardless of the choosenim or Nim version installed.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $nimbleBinPath = Join-Path $env:USERPROFILE '.nimble' 'bin'
    $nimbleBinPath = [System.IO.Path]::GetFullPath($nimbleBinPath)

    Write-DebugLog -Scope "NIM-PATH" `
        -Message "Nimble bin directory: $nimbleBinPath"

    return $nimbleBinPath
}

function Update-MachinePathWithNim {
    <#
    .SYNOPSIS
        Registers the nimble bin directory in the Machine PATH.

    .DESCRIPTION
        Adds the nimble bin directory to the Machine-level PATH environment
        variable so that nim, nimble, and all Nim ecosystem tools are
        available to all users in new sessions. Also updates the current
        process PATH for immediate availability in this session.

    .PARAMETER NimbleBinDirectory
        The absolute path to the nimble bin directory to register.

    .OUTPUTS
        None. Throws if the directory does not exist or PATH update fails.

    .EXAMPLE
        Update-MachinePathWithNim `
            -NimbleBinDirectory "C:\Users\user\.nimble\bin"

    .NOTES
        Requires administrative privileges to modify Machine PATH.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Nimble bin directory")]
        [ValidateNotNullOrEmpty()]
        [string]$NimbleBinDirectory
    )

    Write-DebugLog -Scope "NIM-PATH" `
        -Message "Registering nimble bin in Machine PATH: $NimbleBinDirectory"

    if (-not (Test-Path -LiteralPath $NimbleBinDirectory -PathType Container)) {
        Write-ErrorLog -Scope "NIM-PATH" `
            -Message "Nimble bin directory not found: $NimbleBinDirectory"

        throw "Nimble bin directory does not exist: $NimbleBinDirectory"
    }

    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $machinePathEntries = $machinePath -split ';'

    if ($machinePathEntries -notcontains $NimbleBinDirectory) {
        $updatedMachinePath = "$NimbleBinDirectory;$machinePath"

        [Environment]::SetEnvironmentVariable(
            'Path', $updatedMachinePath, 'Machine'
        )

        Write-InfoLog -Scope "NIM-PATH" `
            -Message "Machine PATH updated with: $NimbleBinDirectory"
    }
    else {
        Write-InfoLog -Scope "NIM-PATH" `
            -Message "Machine PATH already contains: $NimbleBinDirectory"
    }

    $processPathEntries = $env:PATH -split ';'

    if ($processPathEntries -notcontains $NimbleBinDirectory) {
        $env:PATH = "$NimbleBinDirectory;$env:PATH"

        Write-InfoLog -Scope "NIM-PATH" `
            -Message "Process PATH updated with: $NimbleBinDirectory"
    }
}

#endregion

#region Verification Functions

function Test-NimInstallation {
    <#
    .SYNOPSIS
        Verifies that nim is accessible and reports its version.

    .DESCRIPTION
        Resolves the nim command in the current PATH and invokes
        nim --version to confirm the installation is functional.
        Returns true if nim is found and exits with code 0.

    .OUTPUTS
        System.Boolean. Returns $true if nim is accessible and working.

    .EXAMPLE
        if (Test-NimInstallation) {
            Write-InfoLog -Scope "NIM-VERIFY" -Message "Nim is ready"
        }

    .NOTES
        Returns $false without throwing; caller decides how to handle.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    Write-DebugLog -Scope "NIM-VERIFY" `
        -Message "Verifying nim installation"

    $nimCommand = Get-Command -Name 'nim' -ErrorAction SilentlyContinue

    if (-not $nimCommand) {
        Write-ErrorLog -Scope "NIM-VERIFY" `
            -Message "nim command not found in PATH after installation"

        return $false
    }

    & nim --version

    if ($LASTEXITCODE -ne 0) {
        Write-ErrorLog -Scope "NIM-VERIFY" `
            -Message "nim --version exited with code: $LASTEXITCODE"

        return $false
    }

    Write-InfoLog -Scope "NIM-VERIFY" `
        -Message "Nim installation verified successfully"

    return $true
}

#endregion

#region Main Script Execution

Initialize-ScriptEnvironment
$null = Test-IsInteractivePowerShell
Invoke-PowerShellCoreTransition
Assert-WindowsPlatform
Assert-PowerShellVersionStrict

if (-not (Test-IsAdministrator)) {
    Invoke-ElevationRequest -ScriptPath $PSCommandPath
}

try {
    Write-InfoLog -Scope "SCRIPT-MAIN" `
        -Message "Starting Nim setup via choosenim"

    Assert-ChoosenimInstalled

    Invoke-NimStableInstallation

    $nimbleBinDirectory = Get-NimbleBinDirectory

    Update-MachinePathWithNim -NimbleBinDirectory $nimbleBinDirectory

    if (-not (Test-NimInstallation)) {
        throw "Nim installation verification failed"
    }

    Write-InfoLog -Scope "SCRIPT-MAIN" `
        -Message "Success: Nim setup completed successfully"

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
