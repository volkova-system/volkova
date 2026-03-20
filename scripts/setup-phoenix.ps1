<# :
@echo off
echo.
echo Error: This script must be run from a PowerShell terminal.
echo.
exit /b 1
#>

<#
.SYNOPSIS
    Installs the Phoenix framework for Elixir development.

.DESCRIPTION
    Validates that Erlang/OTP and Elixir are installed, then executes the
    Phoenix framework installation via "mix archive.install hex phx_new".
    Verifies successful installation and confirms Phoenix is ready for use.

    Does not require administrative privileges.

    See helps/powershell-script-format.help for format specifications.

.NOTES
    Author: Richeve Bebedor <richeve.bebedor+vs-scripts@gmail.com>
    Version: 0.0.0
    Last Modified: 2026-02-27
    Platform: Windows
    Requires: PowerShell 7.6.0 or later

.EXAMPLE
    .\setup-phoenix.ps1

.EXIT CODES
    0 - Success: Phoenix setup completed successfully
    1 - Failure: Any validation, installation, or verification step failed
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest

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

function Assert-ErlangOtpInstallation {
    <#
    .SYNOPSIS
        Validates that Erlang/OTP is installed and accessible.

    .DESCRIPTION
        Checks if the Erlang/OTP erl command is accessible in the system
        PATH. Logs version information if found. Throws an exception if
        Erlang/OTP is not found.

    .OUTPUTS
        None. Throws an exception if Erlang/OTP is not found.

    .EXAMPLE
        Assert-ErlangOtpInstallation

    .NOTES
        Uses Get-Command to check for erl command accessibility.
        Implements single reliable flow: check → log → succeed or throw.
    #>
    [CmdletBinding()]
    param()

    Write-DebugLog -Scope "ERLANG-CHECK" `
        -Message "Checking Erlang/OTP installation"

    $erlCommand = Get-Command -Name 'erl' -ErrorAction SilentlyContinue

    if (-not $erlCommand) {
        Write-ErrorLog -Scope "ERLANG-CHECK" `
            -Message "Erlang/OTP not found in PATH"

        throw "Erlang/OTP is required but not found in PATH"
    }

    Write-InfoLog -Scope "ERLANG-CHECK" `
        -Message "Erlang/OTP found at: $($erlCommand.Source)"
}

function Assert-ElixirInstallation {
    <#
    .SYNOPSIS
        Validates that Elixir and Mix are installed and accessible.

    .DESCRIPTION
        Checks if the Elixir elixir command and Mix mix command are
        accessible in the system PATH. Logs version information if found.
        Throws an exception if either is not found.

    .OUTPUTS
        None. Throws an exception if Elixir or Mix is not found.

    .EXAMPLE
        Assert-ElixirInstallation

    .NOTES
        Uses Get-Command to check for elixir and mix command accessibility.
        Implements single reliable flow: check → log → succeed or throw.
    #>
    [CmdletBinding()]
    param()

    Write-DebugLog -Scope "ELIXIR-CHECK" `
        -Message "Checking Elixir installation"

    $elixirCommand = Get-Command -Name 'elixir' `
        -ErrorAction SilentlyContinue

    if (-not $elixirCommand) {
        Write-ErrorLog -Scope "ELIXIR-CHECK" `
            -Message "Elixir not found in PATH"

        throw "Elixir is required but not found in PATH"
    }

    Write-InfoLog -Scope "ELIXIR-CHECK" `
        -Message "Elixir found at: $($elixirCommand.Source)"

    Write-DebugLog -Scope "ELIXIR-CHECK" `
        -Message "Checking Mix command availability"

    $mixCommand = Get-Command -Name 'mix' -ErrorAction SilentlyContinue

    if (-not $mixCommand) {
        Write-ErrorLog -Scope "ELIXIR-CHECK" `
            -Message "Mix command not found in PATH"

        throw "Mix command is required but not found in PATH"
    }

    Write-InfoLog -Scope "ELIXIR-CHECK" `
        -Message "Mix found at: $($mixCommand.Source)"
}

function Invoke-PhoenixInstallation {
    <#
    .SYNOPSIS
        Executes the Phoenix framework installation command.

    .DESCRIPTION
        Runs "mix archive.install hex phx_new" to install the Phoenix
        framework. Captures command output for logging. Throws an exception
        if the command fails.

    .OUTPUTS
        None. Throws an exception if installation fails.

    .EXAMPLE
        Invoke-PhoenixInstallation

    .NOTES
        Implements single reliable flow: execute → check exit code →
        log → succeed or throw.
    #>
    [CmdletBinding()]
    param()

    Write-InfoLog -Scope "PHOENIX-INSTALL" `
        -Message "Starting Phoenix framework installation"

    try {
        Write-DebugLog -Scope "PHOENIX-INSTALL" `
            -Message "Executing: mix archive.install hex phx_new"

        & mix archive.install hex phx_new --force

        if ($LASTEXITCODE -ne 0) {
            Write-ErrorLog -Scope "PHOENIX-INSTALL" `
                -Message ("Phoenix installation failed with exit code: " +
                    "$LASTEXITCODE")

            throw "Phoenix installation command failed"
        }

        Write-InfoLog -Scope "PHOENIX-INSTALL" `
            -Message "Phoenix installation completed successfully"
    }
    catch {
        Write-ErrorLog -Scope "PHOENIX-INSTALL" `
            -Message "Installation error: $($_.Exception.Message)"

        throw
    }
}

function Assert-PhoenixInstallation {
    <#
    .SYNOPSIS
        Verifies that Phoenix was installed successfully.

    .DESCRIPTION
        Executes "mix phx.new --version" to verify that the Phoenix
        framework is accessible and ready for use. Throws an exception
        if verification fails.

    .OUTPUTS
        None. Throws an exception if verification fails.

    .EXAMPLE
        Assert-PhoenixInstallation

    .NOTES
        Implements single reliable flow: execute → check exit code →
        log → succeed or throw.
    #>
    [CmdletBinding()]
    param()

    Write-DebugLog -Scope "PHOENIX-VERIFY" `
        -Message "Verifying Phoenix installation"

    try {
        Write-DebugLog -Scope "PHOENIX-VERIFY" `
            -Message "Executing: mix phx.new --version"

        & mix phx.new --version

        if ($LASTEXITCODE -ne 0) {
            Write-ErrorLog -Scope "PHOENIX-VERIFY" `
                -Message ("Phoenix verification failed with exit code: " +
                    "$LASTEXITCODE")

            throw "Phoenix verification command failed"
        }

        Write-InfoLog -Scope "PHOENIX-VERIFY" `
            -Message "Phoenix installation verified successfully"
    }
    catch {
        Write-ErrorLog -Scope "PHOENIX-VERIFY" `
            -Message "Verification error: $($_.Exception.Message)"

        throw
    }
}

function Invoke-PrimaryWorkflow {
    <#
    .SYNOPSIS
        Orchestrates the complete Phoenix setup workflow.

    .DESCRIPTION
        Executes the Phoenix setup process in sequence: validates
        Erlang/OTP, validates Elixir and Mix, installs Phoenix, and
        verifies installation. Throws an exception if any step fails.

    .OUTPUTS
        None. Throws an exception if any workflow step fails.

    .EXAMPLE
        Invoke-PrimaryWorkflow

    .NOTES
        Implements single reliable flow: validate erlang → validate
        elixir → install phoenix → verify phoenix → succeed or throw.
    #>
    [CmdletBinding()]
    param()

    Write-InfoLog -Scope "SCRIPT-MAIN" `
        -Message "Starting Phoenix setup workflow"

    Assert-ErlangOtpInstallation

    Assert-ElixirInstallation

    Invoke-PhoenixInstallation

    Assert-PhoenixInstallation

    Write-InfoLog -Scope "SCRIPT-MAIN" `
        -Message "Phoenix setup workflow completed successfully"
}

#endregion

#region Main Script Execution

Initialize-ScriptEnvironment
$null = Test-IsInteractivePowerShell
Invoke-PowerShellCoreTransition
Assert-WindowsPlatform
Assert-PowerShellVersionStrict

try {
    Write-InfoLog -Scope "SCRIPT-MAIN" `
        -Message "Starting Phoenix framework setup"

    Invoke-PrimaryWorkflow

    Write-InfoLog -Scope "SCRIPT-MAIN" `
        -Message "Success: Phoenix setup completed successfully"

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
