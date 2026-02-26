<# :
@echo off
echo.
echo Error: This script must be run from a PowerShell terminal.
echo.
exit /b 1
#>

<#
.SYNOPSIS
    Detects Erlang/OTP version and installs compatible Elixir.

.DESCRIPTION
    Automatically detects the installed Erlang/OTP major version, queries the Hex
    builds API to find the latest compatible Elixir version, and installs it using
    the official Elixir installer. Updates the PATH environment variable for the
    current session.

    Requires administrative privileges for system-wide installation.

    See helps/powershell-core-module-format.help for core function specifications.

.NOTES
    Author: Richeve Bebedor <richeve.bebedor+vs-scripts@gmail.com>
    Version: 0.0.0
    Last Modified: 2026-02-27
    Platform: Windows only
    Requirements: pwsh 7.5.4, Administrator privileges, Erlang/OTP

.EXAMPLE
    # Detects OTP version, finds latest Elixir, and installs it.
    .\scripts\setup-elixir.ps1

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

function Get-ErlangOtpMajorVersion {
    <#
    .SYNOPSIS
        Retrieves the installed Erlang/OTP major version.

    .DESCRIPTION
        Executes the erl command to query the Erlang runtime for the installed OTP
        release version. Returns the major version number as a string.

    .OUTPUTS
        System.String. Returns the OTP major version (e.g., "28").

    .EXAMPLE
        $otpMajor = Get-ErlangOtpMajorVersion
        Write-InfoLog -Scope "ERLANG-CHECK" -Message "OTP: $otpMajor"

    .NOTES
        Requires Erlang/OTP to be installed and available in PATH.
        Throws an error if erl command is not found or fails.

    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    Write-DebugLog -Scope "ERLANG-CHECK" `
        -Message "Detecting Erlang/OTP major version"

    try {
        $erlCommand = Get-Command -Name 'erl' -ErrorAction SilentlyContinue

        if (-not $erlCommand) {
            Write-ErrorLog -Scope "ERLANG-CHECK" `
                -Message "Erlang/OTP not found in PATH"

            throw "Erlang/OTP is required but not installed"
        }

        $erlangVersion = (& erl -noshell `
            -eval "io:format(""~s"", [erlang:system_info(otp_release)])" `
            -s init stop 2>$null).Trim()

        if (-not $erlangVersion) {
            Write-ErrorLog -Scope "ERLANG-CHECK" `
                -Message "Failed to detect Erlang/OTP version"

            throw "Could not determine Erlang/OTP version"
        }

        Write-InfoLog -Scope "ERLANG-CHECK" `
            -Message "Detected Erlang/OTP major version: $erlangVersion"

        return $erlangVersion
    }
    catch {
        Write-ErrorLog -Scope "ERLANG-CHECK" `
            -Message "Erlang/OTP detection failed: $($_.Exception.Message)"

        throw
    }
}

function Get-LatestElixirVersion {
    <#
    .SYNOPSIS
        Queries Hex builds API for latest Elixir version for OTP.

    .DESCRIPTION
        Fetches the Hex builds list from builds.hex.pm, filters for Elixir versions
        compatible with the specified OTP major version, and returns the latest
        available version.

    .PARAMETER OtpMajorVersion
        The Erlang/OTP major version to find compatible Elixir for.

    .OUTPUTS
        System.String. Returns the latest Elixir version (e.g., "1.17.2").

    .EXAMPLE
        $elixirVersion = Get-LatestElixirVersion -OtpMajorVersion "28"
        Write-InfoLog -Scope "ELIXIR-QUERY" -Message "Latest: $elixirVersion"

    .NOTES
        Requires internet connectivity to access builds.hex.pm.
        Throws an error if no compatible version is found.

    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "OTP major version")]
        [ValidateNotNullOrEmpty()]
        [string]$OtpMajorVersion
    )

    Write-DebugLog -Scope "ELIXIR-QUERY" `
        -Message "Querying Hex builds for OTP $OtpMajorVersion"

    try {
        $buildsUrl = 'https://builds.hex.pm/builds/elixir/builds.txt'

        Write-InfoLog -Scope "ELIXIR-QUERY" `
            -Message "Fetching builds list from: $buildsUrl"

        $buildsContent = (Invoke-WebRequest -Uri $buildsUrl `
            -ErrorAction Stop).Content

        $buildLines = $buildsContent -split "`n"

        Write-DebugLog -Scope "ELIXIR-QUERY" `
            -Message "Processing $($buildLines.Count) build entries"

        $pattern = "^v\d+\.\d+\.\d+-otp-$([regex]::Escape($OtpMajorVersion))\b"

        $compatibleBuilds = $buildLines |
            Where-Object {
                $_ -match $pattern
            } |
            ForEach-Object {
                if ($_ -match '^v(?<ver>\d+\.\d+\.\d+)-otp-(?<otp>\d+)') {
                    [PSCustomObject]@{ Version = [version]$Matches.ver }
                }
            } |
            Sort-Object Version -Descending

        if (-not $compatibleBuilds) {
            Write-ErrorLog -Scope "ELIXIR-QUERY" `
                -Message "No Elixir builds found for OTP $OtpMajorVersion"

            throw "No compatible Elixir version found for OTP $OtpMajorVersion"
        }

        $latestVersion = $compatibleBuilds[0].Version.ToString()

        Write-InfoLog -Scope "ELIXIR-QUERY" `
            -Message "Latest compatible Elixir: $latestVersion"

        return $latestVersion
    }
    catch {
        Write-ErrorLog -Scope "ELIXIR-QUERY" `
            -Message "Query failed: $($_.Exception.Message)"

        throw
    }
}

function Invoke-ElixirInstallation {
    <#
    .SYNOPSIS
        Downloads and executes the Elixir installer.

    .DESCRIPTION
        Downloads the official Elixir installer batch script from elixir-lang.org
        and executes it with the specified version. Uses the waste directory for
        temporary files.

    .PARAMETER ElixirVersion
        The Elixir version to install (e.g., "1.17.2").

    .OUTPUTS
        None. Throws an error if installation fails.

    .EXAMPLE
        Invoke-ElixirInstallation -ElixirVersion "1.17.2"

    .NOTES
        Downloads installer to waste directory and cleans up after execution.

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Elixir version")]
        [ValidateNotNullOrEmpty()]
        [string]$ElixirVersion
    )

    Write-InfoLog -Scope "ELIXIR-INSTALL" `
        -Message "Starting Elixir $ElixirVersion installation"

    try {
        $repositoryRoot = Get-RepositoryRoot
        $wasteDirectory = Join-Path $repositoryRoot 'waste'

        if (-not (Test-Path -LiteralPath $wasteDirectory)) {
            Write-ErrorLog -Scope "ELIXIR-INSTALL" `
                -Message "Waste directory not found: $wasteDirectory"

            throw "Waste directory not found"
        }

        $installerPath = Join-Path $wasteDirectory 'elixir-install.bat'

        Write-InfoLog -Scope "ELIXIR-INSTALL" `
            -Message "Downloading installer to: $installerPath"

        $installerUrl = 'https://elixir-lang.org/install.bat'

        Invoke-WebRequest -Uri $installerUrl `
            -OutFile $installerPath `
            -ErrorAction Stop

        Write-InfoLog -Scope "ELIXIR-INSTALL" `
            -Message "Executing installer for version: $ElixirVersion"

        & $installerPath "elixir@$ElixirVersion"

        if ($LASTEXITCODE -ne 0) {
            throw "Installer exited with code: $LASTEXITCODE"
        }

        Write-InfoLog -Scope "ELIXIR-INSTALL" `
            -Message "Installation completed successfully"

        # Clean up installer
        if (Test-Path -LiteralPath $installerPath) {
            Remove-Item -LiteralPath $installerPath -Force

            Write-DebugLog -Scope "ELIXIR-INSTALL" `
                -Message "Cleaned up installer file"
        }
    }
    catch {
        Write-ErrorLog -Scope "ELIXIR-INSTALL" `
            -Message "Installation failed: $($_.Exception.Message)"

        throw
    }
}

function Update-SessionPath {
    <#
    .SYNOPSIS
        Updates PATH for current session with Elixir binary directory.

    .DESCRIPTION
        Constructs the path to the installed Elixir binary directory based on
        version and OTP major version, then prepends it to the PATH environment
        variable for the current session.

    .PARAMETER ElixirVersion
        The installed Elixir version (e.g., "1.17.2").

    .PARAMETER OtpMajorVersion
        The Erlang/OTP major version (e.g., "28").

    .OUTPUTS
        None. Updates $env:PATH for current session.

    .EXAMPLE
        Update-SessionPath -ElixirVersion "1.17.2" -OtpMajorVersion "28"

    .NOTES
        This only affects the current PowerShell session. System-wide
        PATH updates require administrative action outside this script.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Elixir version")]
        [ValidateNotNullOrEmpty()]
        [string]$ElixirVersion,

        [Parameter(Mandatory = $true, HelpMessage = "OTP major version")]
        [ValidateNotNullOrEmpty()]
        [string]$OtpMajorVersion
    )

    Write-DebugLog -Scope "PATH-UPDATE" `
        -Message "Updating PATH for Elixir $ElixirVersion"

    try {
        $installsDirectory = Join-Path $env:USERPROFILE `
            '.elixir-install\installs'

        $elixirBinDirectory = Join-Path $installsDirectory `
            "elixir\$ElixirVersion-otp-$OtpMajorVersion\bin"

        if (-not (Test-Path -LiteralPath $elixirBinDirectory)) {
            Write-ErrorLog -Scope "PATH-UPDATE" `
                -Message "Elixir bin directory not found: $elixirBinDirectory"

            throw "Elixir binary directory not found"
        }

        $env:PATH = "$elixirBinDirectory;$env:PATH"

        Write-InfoLog -Scope "PATH-UPDATE" `
            -Message "PATH updated with: $elixirBinDirectory"
    }
    catch {
        Write-ErrorLog -Scope "PATH-UPDATE" `
            -Message "PATH update failed: $($_.Exception.Message)"

        throw
    }
}

function Test-ElixirInstallation {
    <#
    .SYNOPSIS
        Verifies Elixir installation by checking version.

    .DESCRIPTION
        Executes the elixir command to display version information,
        confirming that Elixir is properly installed and accessible
        in the current PATH.

    .OUTPUTS
        System.Boolean. Returns $true if Elixir is accessible.

    .EXAMPLE
        if (Test-ElixirInstallation) {
            Write-InfoLog -Scope "ELIXIR-VERIFY" -Message "Installation OK"
        }

    .NOTES
        Outputs version information to the console.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    Write-DebugLog -Scope "ELIXIR-VERIFY" `
        -Message "Verifying Elixir installation"

    try {
        $elixirCommand = Get-Command -Name 'elixir' `
            -ErrorAction SilentlyContinue

        if (-not $elixirCommand) {
            Write-ErrorLog -Scope "ELIXIR-VERIFY" `
                -Message "Elixir command not found in PATH"

            return $false
        }

        Write-InfoLog -Scope "ELIXIR-VERIFY" `
            -Message "Displaying Elixir version information"

        & elixir -v

        if ($LASTEXITCODE -eq 0) {
            Write-InfoLog -Scope "ELIXIR-VERIFY" `
                -Message "Elixir installation verified successfully"

            return $true
        }

        Write-ErrorLog -Scope "ELIXIR-VERIFY" `
            -Message "Elixir version check failed with code: $LASTEXITCODE"

        return $false
    }
    catch {
        Write-ErrorLog -Scope "ELIXIR-VERIFY" `
            -Message "Verification failed: $($_.Exception.Message)"

        return $false
    }
}

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
        -Message "Starting Elixir setup process"

    # Detect Erlang/OTP major version
    $otpMajorVersion = Get-ErlangOtpMajorVersion

    # Query for latest compatible Elixir version
    $elixirVersion = Get-LatestElixirVersion -OtpMajorVersion $otpMajorVersion

    # Download and install Elixir
    Invoke-ElixirInstallation -ElixirVersion $elixirVersion

    # Update PATH for current session
    Update-SessionPath -ElixirVersion $elixirVersion `
        -OtpMajorVersion $otpMajorVersion

    # Verify installation
    if (-not (Test-ElixirInstallation)) {
        throw "Elixir installation verification failed"
    }

    Write-InfoLog -Scope "SCRIPT-MAIN" `
        -Message "Success: Elixir setup completed successfully"

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
