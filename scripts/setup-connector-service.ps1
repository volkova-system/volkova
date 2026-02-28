<# :
@echo off
echo.
echo Error: This script must be run from a PowerShell terminal.
echo.
exit /b 1
#>

<#
.SYNOPSIS
    Automates the scaffolding of Phoenix microservices.

.DESCRIPTION
    The setup-connector-service PowerShell script automates the scaffolding of
    Phoenix microservices. It validates the development environment, creates a new
    Phoenix service with specific configurations, and verifies successful setup.
    The script enforces strict error handling with no graceful degradation,
    ensuring failures are immediately visible to developers.

.PARAMETER ServiceName
    The name of the Phoenix service to create. This will be used as the directory
    name and service identifier.

.NOTES
    Author: Richeve Bebedor <richeve.bebedor963+vs-scripts@proton.me>
    Version: 0.0.0
    Last Modified: 2026-02-28
    Platform: Windows only
    Requirements: pwsh 7.5.4

.EXAMPLE
    # Creates a new Phoenix service named 'setting-service'.
    .\scripts\setup-connector-service.ps1 -ServiceName 'setting-service'

.EXIT CODES
    0 - Success
    1 - Failure (with error message)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true,
        HelpMessage = "The name of the Phoenix service to create.")]
    [ValidateNotNullOrEmpty()]
    [string]$ServiceName
)

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

#region Primary Functions

function Get-RepositoryRoot {
    <#
    .SYNOPSIS
        Gets the repository root directory.

    .DESCRIPTION
        Determines the repository root directory by checking for git
        repository. Returns the absolute path to the repository root.

    .OUTPUTS
        System.String. Returns the absolute path to the repository root.

    .EXAMPLE
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

function Invoke-ParameterValidation {
    <#
    .SYNOPSIS
        Validates the ServiceName parameter.

    .DESCRIPTION
        Validates that the ServiceName parameter is not null, empty, or
        whitespace-only. Throws a terminating error if validation fails.

    .PARAMETER ServiceName
        The service name to validate.

    .EXAMPLE
        # Validates the service name 'setting-service'.
        Invoke-ParameterValidation -ServiceName 'setting-service'

    .NOTES
        This function enforces fail-loud behavior and will terminate the script if
        validation fails.

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            HelpMessage = "The service name to validate.")]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceName
    )

    Write-InfoLog -Scope "SETUP-PARAM" -Message "Starting parameter validation"

    # Validate ServiceName is not null, empty, or whitespace-only
    if ([string]::IsNullOrWhiteSpace($ServiceName)) {
        $errorMessage = (
            "ServiceName parameter is required and " +
            "cannot be empty or whitespace-only."
        )
        Write-ErrorLog -Scope "SETUP-PARAM" -Message $errorMessage

        throw $errorMessage
    }

    $serviceDirectory = Join-Path (Get-RepositoryRoot) "services" $ServiceName
    if ((Test-Path -LiteralPath $serviceDirectory -PathType Container)) {
        $errorMessage = "ServiceName path exist: $serviceDirectory"
        Write-ErrorLog -Scope "SETUP-PARAM" -Message $errorMessage

        throw $errorMessage
    }

    Write-InfoLog -Scope "SETUP-PARAM" `
        -Message "Parameter validation completed successfully"
}

function Assert-ErlangInstallation {
    <#
    .SYNOPSIS
        Validates Erlang installation.

    .DESCRIPTION
        Validates that Erlang is installed and accessible. Throws a
        terminating error with installation instructions if validation fails.

    .EXAMPLE
        # Validates Erlang installation.
        Assert-ErlangInstallation

    .NOTES
        This function enforces fail-loud behavior and will terminate the
        script if validation fails.

    #>
    [CmdletBinding()]
    param()

    Write-InfoLog -Scope "SETUP-ERLANG" `
        -Message "Checking Erlang installation"

    # Check if Erlang is installed and accessible
    $erlangCommand = Get-Command -Name 'erl' -ErrorAction SilentlyContinue

    if (-not $erlangCommand) {
        $errorMessage = "Erlang is not installed or not accessible in PATH."
        Write-ErrorLog -Scope "SETUP-ERLANG" -Message $errorMessage

        throw $errorMessage
    }

    Write-InfoLog -Scope "SETUP-ERLANG" `
        -Message "Erlang validation completed successfully"
}

function Assert-ElixirInstallation {
    <#
    .SYNOPSIS
        Validates Elixir installation.

    .DESCRIPTION
        Validates that Elixir is installed and accessible. Throws a terminating
        error if validation fails.

    .EXAMPLE
        # Validates Elixir installation.
        Assert-ElixirInstallation

    .NOTES
        This function enforces fail-loud behavior and will terminate the
        script if validation fails.

    #>
    [CmdletBinding()]
    param()

    Write-InfoLog -Scope "SETUP-ELIXIR" -Message "Checking Elixir installation"

    # Check if Elixir is installed and accessible
    $elixirCommand = Get-Command -Name 'elixir' -ErrorAction SilentlyContinue

    if (-not $elixirCommand) {
        $errorMessage = "Elixir is not installed or not accessible in PATH."
        Write-ErrorLog -Scope "SETUP-ELIXIR" -Message $errorMessage

        throw $errorMessage
    }

    Write-InfoLog -Scope "SETUP-ELIXIR" `
        -Message "Elixir validation completed successfully"
}

function Assert-PhoenixInstallation {
    <#
    .SYNOPSIS
        Validates Phoenix installation presence.

    .DESCRIPTION
        Validates that Phoenix is installed via Mix and accessible. Executes
        "mix phx.new --version" to confirm the installer is available. Throws a
        terminating error with installation instructions if validation fails.

    .EXAMPLE
        Assert-PhoenixInstallation
        Validates Phoenix installation presence.

    .NOTES
        This function enforces fail-loud behavior and will terminate the script if
        validation fails.

    #>
    [CmdletBinding()]
    param()

    Write-InfoLog -Scope "SETUP-PHOENIX" `
        -Message "Checking Phoenix installation"

    $mixCommand = Get-Command -Name 'mix' -ErrorAction SilentlyContinue

    if (-not $mixCommand) {
        $errorMessage = "Mix is not installed or not accessible in PATH."
        Write-ErrorLog -Scope "SETUP-PHOENIX" -Message $errorMessage

        throw $errorMessage
    }

    try {
        & mix phx.new --version 2>&1

        if ($LASTEXITCODE -ne 0) {
            $errorMessage = "Phoenix is not installed or not accessible via Mix."
            Write-ErrorLog -Scope "SETUP-PHOENIX" -Message $errorMessage

            throw $errorMessage
        }

        Write-InfoLog -Scope "SETUP-PHOENIX" `
            -Message "Phoenix installation validated successfully"
    }
    catch {
        throw
    }
}

function Invoke-EnvironmentValidation {
    <#
    .SYNOPSIS
        Orchestrates all environment validations.

    .DESCRIPTION
        Orchestrates the validation of Erlang, Elixir, and Phoenix installations by
        calling each validation function in sequence. Throws a terminating error if
        any validation fails.

    .EXAMPLE
        # Validates all required environment components.
        Invoke-EnvironmentValidation

    .NOTES
        This function enforces fail-loud behavior and will terminate the script if
        any validation fails. All errors from individual validation functions
        propagate as terminating errors.

    #>
    [CmdletBinding()]
    param()

    Write-InfoLog -Scope "SETUP-ENV" `
        -Message "Starting environment validation"

    # Call Erlang validation
    Assert-ErlangInstallation

    # Call Elixir validation
    Assert-ElixirInstallation

    # Call Phoenix validation
    Assert-PhoenixInstallation

    Write-InfoLog -Scope "SETUP-ENV" `
        -Message "Environment validation completed successfully"
}

function Invoke-ServiceGeneration {
    <#
    .SYNOPSIS
        Generates a new Phoenix service.

    .DESCRIPTION
        Executes the Mix command to create a new Phoenix service with specific
        configurations. The service is created in the services/<service-name>
        directory with flags to exclude HTML, assets, LiveView, mailer,
        dashboard, gettext, and Ecto components. Throws a terminating error
        if the Mix command fails.

    .PARAMETER ServiceName
        The name of the Phoenix service to create.

    .EXAMPLE
        # Creates a new Phoenix service named 'setting-service' in the
        # services/setting-service directory.
        Invoke-ServiceGeneration -ServiceName 'setting-service'

    .NOTES
        This function enforces fail-loud behavior and will terminate the script if
        the Mix command fails. The function uses the powershell-core module for
        command execution.

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            HelpMessage = "The name of the Phoenix service to create.")]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceName
    )

    Write-InfoLog -Scope "SETUP-GEN" `
        -Message "Starting service generation for '$ServiceName'"

    # Ensure services directory exists
    $servicesDirectory = Join-Path (Get-RepositoryRoot) "services"

    if (-not (Test-Path -LiteralPath $servicesDirectory -PathType Container)) {
        try {
            New-Item -LiteralPath $servicesDirectory -ItemType Directory `
                -Force -ErrorAction Stop | Out-Null

            Write-InfoLog -Scope "SETUP-GEN" `
                -Message "Created services directory: $servicesDirectory"
        }
        catch {
            $errorMessage = "Failed to create services directory: $_"
            Write-ErrorLog -Scope "SETUP-GEN" -Message $errorMessage

            throw $errorMessage
        }
    }

    $serviceDirectory = Join-Path $servicesDirectory $ServiceName

    $serviceAppName = $ServiceName -replace "-", "_"
    $serviceModuleName = (
        $ServiceName -split '[-_\s]+' |
        Where-Object { $_.Length -gt 0 } |
        ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1).ToLower() }
    ) -join ''

    # Construct Mix command with required flags
    $mixCommand = "mix"
    $mixArguments = @(
        "phx.new"
        $serviceDirectory
        "--no-html"
        "--no-assets"
        "--no-live"
        "--no-mailer"
        "--no-dashboard"
        "--no-gettext"
        "--no-ecto"
        "--app"
        $serviceAppName
        "--module"
        $serviceModuleName
        "--install"
    )

    Write-InfoLog -Scope "SETUP-GEN" `
        -Message "Executing Mix command: $mixCommand $($mixArguments -join ' ')"

    # Execute Mix command in services directory
    try {
        # Execute Mix command and capture output
        & $mixCommand `
            "phx.new" `
            $serviceDirectory `
            "--no-html" `
            "--no-assets" `
            "--no-live" `
            "--no-mailer" `
            "--no-dashboard" `
            "--no-gettext" `
            "--no-ecto" `
            "--app" $serviceAppName `
            "--module" $serviceModuleName `
            "--install"

        # Check exit code
        if ($LASTEXITCODE -ne 0) {
            $errorMessage = "Failed to generate Phoenix service."
            Write-ErrorLog -Scope "SETUP-GEN" -Message $errorMessage

            throw $errorMessage
        }

        Write-InfoLog -Scope "SETUP-GEN" `
            -Message "Service generation completed successfully"
    }
    catch {
        Write-ErrorLog -Scope "SETUP-GEN" -Message $_

        throw
    }
}

function Test-ServiceDirectory {
    <#
    .SYNOPSIS
        Verifies that the service directory exists.

    .DESCRIPTION
        Verifies that the services/<service-name> directory exists after service
        generation. Throws a terminating error with the expected path if the
        directory is not found.

    .PARAMETER ServiceName
        The name of the Phoenix service to verify.

    .EXAMPLE
        # Verifies that the services/setting-service directory exists.
        Test-ServiceDirectory -ServiceName 'setting-service'

    .NOTES
        This function enforces fail-loud behavior and will terminate the script if
        the directory is not found.

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            HelpMessage = "The name of the Phoenix service.")]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceName
    )

    Write-InfoLog -Scope "SETUP-VERIFY" `
        -Message "Checking service directory for '$ServiceName'"

    # Construct expected service directory path
    $serviceDirectory = Join-Path (Get-RepositoryRoot) "services" $ServiceName

    Write-InfoLog -Scope "SETUP-VERIFY" `
        -Message "Expected directory: $serviceDirectory"

    # Verify directory exists
    if (-not (Test-Path -LiteralPath $serviceDirectory -PathType Container)) {
        $errorMessage = "Service directory not found.`n" +
            "Expected path: $serviceDirectory"
        Write-ErrorLog -Scope "SETUP-VERIFY" -Message $errorMessage

        throw $errorMessage
    }

    Write-InfoLog -Scope "SETUP-VERIFY" `
        -Message "Service directory verified: $serviceDirectory"
}

function Test-CriticalFiles {
    <#
    .SYNOPSIS
        Verifies that critical service files exist.

    .DESCRIPTION
        Verifies that all critical files exist in the service directory:
        mix.exs, lib/<service-name>/application.ex, and config/config.exs.
        Throws a terminating error with the missing file path if any file
        is not found.

    .PARAMETER ServiceName
        The name of the Phoenix service to verify.

    .EXAMPLE
        # Verifies that all critical files exist in the services/setting-service
        # directory.
        Test-CriticalFiles -ServiceName 'setting-service'

    .NOTES
        This function enforces fail-loud behavior and will terminate the
        script if any critical file is missing.

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            HelpMessage = "The name of the Phoenix service.")]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceName
    )

    Write-InfoLog -Scope "SETUP-VERIFY" `
        -Message "Checking critical files for '$ServiceName'"

    # Construct service directory path
    $serviceDirectory = Join-Path (Get-RepositoryRoot) "services" $ServiceName

    # Derive app name (snake_case) for critical file checks
    $serviceAppName = $ServiceName -replace "-", "_"

    # Define critical files to check
    $criticalFiles = @(
        @{
            Name = "mix.exs"
            Path = Join-Path $serviceDirectory "mix.exs"
        },
        @{
            Name = "lib/$serviceAppName/application.ex"
            Path = Join-Path $serviceDirectory "lib" $serviceAppName "application.ex"
        },
        @{
            Name = "config/config.exs"
            Path = Join-Path $serviceDirectory "config" "config.exs"
        }
    )

    # Check each critical file
    foreach ($file in $criticalFiles) {
        Write-InfoLog -Scope "SETUP-VERIFY" `
            -Message "Checking for critical file: $($file.Name)"

        if (-not (Test-Path -LiteralPath $file.Path -PathType Leaf)) {
            $errorMessage = "Critical file missing.`n" +
                "Missing file: $($file.Name)`n" +
                "Expected location: $($file.Path)"
            Write-ErrorLog -Scope "SETUP-VERIFY" -Message $errorMessage

            throw $errorMessage
        }

        Write-InfoLog -Scope "SETUP-VERIFY" `
            -Message "File found: $($file.Name)"
    }

    Write-InfoLog -Scope "SETUP-VERIFY" `
        -Message "All critical files verified successfully"
}

function Invoke-ServiceVerification {
    <#
    .SYNOPSIS
        Orchestrates service verification.

    .DESCRIPTION
        Orchestrates the verification of the service structure by calling
        directory and file verification functions. Logs a success message
        upon completion. Throws a terminating error if any verification fails.

    .PARAMETER ServiceName
        The name of the Phoenix service to verify.

    .EXAMPLE
        Invoke-ServiceVerification -ServiceName 'setting-service'
        Verifies the service structure for 'setting-service'.

    .NOTES
        This function enforces fail-loud behavior and will terminate the
        script if any verification fails. All errors from individual
        verification functions propagate as terminating errors.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            HelpMessage = "The name of the Phoenix service.")]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceName
    )

    Write-InfoLog -Scope "SETUP-VERIFY" `
        -Message "Starting service verification for '$ServiceName'"

    # Call Test-ServiceDirectory with ServiceName
    Test-ServiceDirectory -ServiceName $ServiceName

    # Call Test-CriticalFiles with ServiceName
    Test-CriticalFiles -ServiceName $ServiceName

    # Log success message upon completion
    Write-InfoLog -Scope "SETUP-VERIFY" `
        -Message "Service verification completed successfully"

    Write-InfoLog -Scope "SETUP-VERIFY" `
        -Message "Service '$ServiceName' created successfully"
}

function Invoke-PrimaryWorkflow {
    <#
    .SYNOPSIS
        Primary workflow implementation for service setup.

    .DESCRIPTION
        Orchestrates the entire service setup process, including parameter
        validation, environment validation, service generation, and
        verification.

    .PARAMETER ServiceName
        The name of the service to create.

    .NOTES
        This function is the main entry point for the script's logic.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            HelpMessage = "The name of the service to create.")]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceName
    )

    Write-InfoLog -Scope "SETUP-MAIN" `
        -Message "Starting setup-connector-service workflow"

    if (-not (Test-RepositoryRoot)) {
        Write-ErrorLog -Scope "SETUP-MAIN" `
            -Message "Repository root directory not found."

        throw "Repository root directory not found."
    }

    # Call Invoke-ParameterValidation with ServiceName
    Invoke-ParameterValidation -ServiceName $ServiceName

    # Call Invoke-EnvironmentValidation
    Invoke-EnvironmentValidation

    # Call Invoke-ServiceGeneration with ServiceName
    Invoke-ServiceGeneration -ServiceName $ServiceName

    # Call Invoke-ServiceVerification with ServiceName
    Invoke-ServiceVerification -ServiceName $ServiceName

    Write-InfoLog -Scope "SETUP-MAIN" `
        -Message "Workflow completed successfully"
}

#endregion

#region Main Script Execution

Initialize-ScriptEnvironment
Assert-WindowsPlatform
Test-IsInteractivePowerShell
Invoke-PowerShellCoreTransition
Assert-PowerShellVersionStrict

try {
    # Call the primary workflow
    Invoke-PrimaryWorkflow -ServiceName $ServiceName

    # Exit with code 0 on success
    exit 0
}
catch {
    # Log all errors with full context and stack trace
    Write-ErrorLog -Scope "SETUP-MAIN" `
        -Message "Script execution failed: $($_.Exception.Message)"

    # Log stack trace for debugging
    Write-DebugLog -Scope "SETUP-MAIN" `
        -Message "Stack trace: $($_.ScriptStackTrace)"

    # Exit with code 1 on any failure
    exit 1
}

#endregion
