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

function Get-ErlangOtpVersion {
    <#
    .SYNOPSIS
        Retrieves the installed Erlang/OTP major and full versions.

    .DESCRIPTION
        Searches for Erlang/OTP in the following order:
        1. Current PATH
        2. Common WinGet installation paths (e.g., C:\Program Files\Erlang OTP)
        3. Using 'winget list' to find the installation status

        If found but not in the current session PATH, it updates the session
        PATH to include the Erlang bin directory. Returns an object containing
        both major and full versions.

    .OUTPUTS
        PSCustomObject. Returns an object with 'Major', 'Full', and 'BinPath' properties.

    .EXAMPLE
        $otp = Get-ErlangOtpVersion
        Write-InfoLog -Scope "ERLANG-CHECK" -Message "OTP: $($otp.Full) (Major: $($otp.Major))"

    .NOTES
        Throws an error if Erlang/OTP cannot be found.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    Write-DebugLog -Scope "ERLANG-CHECK" `
        -Message "Detecting Erlang/OTP versions"

    $erlBinPath = $null
    $erlCommand = Get-Command -Name 'erl' -ErrorAction SilentlyContinue

    if ($erlCommand) {
        $erlBinPath = [System.IO.Path]::GetDirectoryName($erlCommand.Source)
        Write-DebugLog -Scope "ERLANG-CHECK" -Message "Found erl in PATH: $erlBinPath"
    }
    else {
        # Search common WinGet path
        $commonPaths = @(
            "C:\Program Files\Erlang OTP\bin",
            "C:\Program Files (x86)\Erlang OTP\bin"
        )

        foreach ($path in $commonPaths) {
            if (Test-Path -LiteralPath (Join-Path $path "erl.exe")) {
                $erlBinPath = $path
                Write-InfoLog -Scope "ERLANG-CHECK" `
                    -Message "Found Erlang in common WinGet path: $erlBinPath"

                # Update session PATH immediately
                $env:PATH = "$erlBinPath;$env:PATH"
                break
            }
        }
    }

    # If still not found, check winget specifically
    if (-not $erlBinPath) {
        Write-DebugLog -Scope "ERLANG-CHECK" -Message "Searching via winget"
        $wingetCheck = (& winget list Erlang.ErlangOTP --accept-source-agreements 2>$null)

        if ($wingetCheck -match "Erlang\.ErlangOTP") {
            # Try to find the path via Registry if winget doesn't give it easily
            # But usually it's in Program Files. If we reach here, we know it's "installed"
            # but we can't find the bin. Let's try one more deep search.
            Write-WarningLog -Scope "ERLANG-CHECK" `
                -Message "Erlang found via winget but bin path not determined. Searching Program Files..."

            $foundErl = Get-ChildItem -Path "C:\Program Files\Erlang OTP*", "C:\Program Files (x86)\Erlang OTP*" `
                -Filter "erl.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

            if ($foundErl) {
                $erlBinPath = $foundErl.DirectoryName
                Write-InfoLog -Scope "ERLANG-CHECK" `
                    -Message "Found Erlang via deep search: $erlBinPath"

                $env:PATH = "$erlBinPath;$env:PATH"
            }
        }
    }

    if (-not $erlBinPath) {
        Write-ErrorLog -Scope "ERLANG-CHECK" `
            -Message "Erlang/OTP not found in PATH or WinGet installation locations"

        throw "Erlang/OTP is required but not installed or could not be located"
    }

    try {
        $majorVersion = (& erl -noshell `
            -eval "io:format(""~s"", [erlang:system_info(otp_release)])" `
            -s init stop 2>$null).Trim()

        if (-not $majorVersion) {
            throw "Could not determine Erlang/OTP major version"
        }

        # Try to get full version from OTP_VERSION file if possible
        $erlDir = [System.IO.Directory]::GetParent($erlBinPath).FullName
        $otpVersionFile = Join-Path $erlDir "releases\$majorVersion\OTP_VERSION"
        $fullVersion = $majorVersion

        if (Test-Path -LiteralPath $otpVersionFile) {
            $fullVersion = (Get-Content -LiteralPath $otpVersionFile -ErrorAction SilentlyContinue).Trim()
        }

        if (-not $fullVersion) {
            $fullVersion = $majorVersion
        }

        Write-InfoLog -Scope "ERLANG-CHECK" `
            -Message "Detected Erlang/OTP major: $majorVersion, full: $fullVersion at $erlBinPath"

        return [PSCustomObject]@{
            Major   = $majorVersion
            Full    = $fullVersion
            BinPath = $erlBinPath
        }
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
        and executes it with the specified version. To avoid redundant Erlang
        installations, it creates a directory junction from an existing Erlang
        installation (e.g., WinGet) to the installer's expected directory.

    .PARAMETER ElixirVersion
        The Elixir version to install (e.g., "1.17.2").

    .PARAMETER OtpFullVersion
        The Erlang/OTP full version to install for (e.g., "28.3.2").

    .PARAMETER ExistingErlangBinPath
        Optional. The bin path of an existing Erlang installation to use.

    .OUTPUTS
        None. Throws an error if installation fails.

    .EXAMPLE
        Invoke-ElixirInstallation -ElixirVersion "1.17.2" -OtpFullVersion "28.3.2"

    .NOTES
        Downloads installer to waste directory and cleans up after execution.

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Elixir version")]
        [ValidateNotNullOrEmpty()]
        [string]$ElixirVersion,

        [Parameter(Mandatory = $true, HelpMessage = "OTP full version")]
        [ValidateNotNullOrEmpty()]
        [string]$OtpFullVersion,

        [Parameter(Mandatory = $false)]
        [string]$ExistingErlangBinPath
    )

    Write-InfoLog -Scope "ELIXIR-INSTALL" `
        -Message "Starting Elixir $ElixirVersion installation for OTP $OtpFullVersion"

    try {
        $repositoryRoot = Get-RepositoryRoot
        $wasteDirectory = [System.IO.Path]::GetFullPath(
            (Join-Path $repositoryRoot 'waste')
        )

        if (-not (Test-Path -LiteralPath $wasteDirectory)) {
            Write-ErrorLog -Scope "ELIXIR-INSTALL" `
                -Message "Waste directory not found: $wasteDirectory"

            throw "Waste directory not found"
        }

        # Handle redundant Erlang installation avoidance
        if ($ExistingErlangBinPath) {
            $existingErlDir = [System.IO.Directory]::GetParent($ExistingErlangBinPath).FullName
            $targetErlDir = Join-Path $env:USERPROFILE ".elixir-install\installs\otp\$OtpFullVersion"

            Write-DebugLog -Scope "ELIXIR-INSTALL" -Message "Checking for existing OTP at: $targetErlDir"

            if (-not (Test-Path -LiteralPath $targetErlDir)) {
                Write-InfoLog -Scope "ELIXIR-INSTALL" `
                    -Message "Linking existing Erlang installation to avoid redundancy"

                # Ensure parent directory exists
                $null = New-Item -Path (Split-Path $targetErlDir) -ItemType Directory -Force

                # Create junction (requires elevation, which we already have)
                $null = cmd /c "mklink /j `"$targetErlDir`" `"$existingErlDir`""

                if ($LASTEXITCODE -ne 0) {
                    Write-WarningLog -Scope "ELIXIR-INSTALL" `
                        -Message "Failed to create junction. Redundant installation may occur."
                }
                else {
                    Write-InfoLog -Scope "ELIXIR-INSTALL" `
                        -Message "Successfully linked $existingErlDir to $targetErlDir"
                }
            }
        }

        $installerPath = Join-Path $wasteDirectory 'elixir-install.bat'

        Write-InfoLog -Scope "ELIXIR-INSTALL" `
            -Message "Downloading installer to: $installerPath"

        $installerUrl = 'https://elixir-lang.org/install.bat'

        Invoke-WebRequest -Uri $installerUrl `
            -OutFile $installerPath `
            -ErrorAction Stop

        Write-InfoLog -Scope "ELIXIR-INSTALL" `
            -Message "Executing installer for version: $ElixirVersion (OTP $OtpFullVersion)"

        & $installerPath "elixir@$ElixirVersion" "otp@$OtpFullVersion"

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

function Update-EnvironmentPath {
    <#
    .SYNOPSIS
        Updates PATH system-wide and for current session with Elixir and OTP.

    .DESCRIPTION
        Constructs the paths to the installed Elixir and compatible Erlang/OTP
        binary directories, then prepends them to the Machine PATH
        environment variable and the current session's PATH.

    .PARAMETER ElixirVersion
        The installed Elixir version (e.g., "1.19.5").

    .PARAMETER OtpMajorVersion
        The Erlang/OTP major version (e.g., "28").

    .PARAMETER OtpFullVersion
        The Erlang/OTP full version (e.g., "28.3.2").

    .PARAMETER ExistingOtpBinPath
        Optional. The existing Erlang bin path to use instead of the default.

    .OUTPUTS
        None. Updates system-wide and session PATH.

    .EXAMPLE
        Update-EnvironmentPath -ElixirVersion "1.19.5" -OtpMajorVersion "28" -OtpFullVersion "28.3.2"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Elixir version")]
        [ValidateNotNullOrEmpty()]
        [string]$ElixirVersion,

        [Parameter(Mandatory = $true, HelpMessage = "OTP major version")]
        [ValidateNotNullOrEmpty()]
        [string]$OtpMajorVersion,

        [Parameter(Mandatory = $true, HelpMessage = "OTP full version")]
        [ValidateNotNullOrEmpty()]
        [string]$OtpFullVersion,

        [Parameter(Mandatory = $false)]
        [string]$ExistingOtpBinPath
    )

    Write-DebugLog -Scope "PATH-UPDATE" `
        -Message "Updating PATH for Elixir $ElixirVersion and OTP $OtpFullVersion"

    try {
        $installsDirectory = Join-Path $env:USERPROFILE `
            '.elixir-install\installs'

        $elixirBinDirectory = Join-Path $installsDirectory `
            "elixir\$ElixirVersion-otp-$OtpMajorVersion\bin"

        $otpBinDirectory = $ExistingOtpBinPath
        if (-not $otpBinDirectory) {
            $otpBinDirectory = Join-Path $installsDirectory `
                "otp\$OtpFullVersion\bin"
        }

        $pathsToUpdate = @($elixirBinDirectory, $otpBinDirectory)

        foreach ($binDir in $pathsToUpdate) {
            if (-not (Test-Path -LiteralPath $binDir)) {
                Write-WarningLog -Scope "PATH-UPDATE" `
                    -Message "Directory not found, skipping PATH update: $binDir"
                continue
            }

            # Update Machine PATH (System-wide)
            $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
            if ($machinePath -split ';' -notcontains $binDir) {
                $newMachinePath = "$binDir;$machinePath"
                [Environment]::SetEnvironmentVariable(
                    'Path', $newMachinePath, 'Machine'
                )

                Write-InfoLog -Scope "PATH-UPDATE" `
                    -Message "System-wide PATH updated with: $binDir"
            }

            # Update Process PATH (Current session)
            if ($env:PATH -split ';' -notcontains $binDir) {
                $env:PATH = "$binDir;$env:PATH"

                Write-InfoLog -Scope "PATH-UPDATE" `
                    -Message "Current session PATH updated with: $binDir"
            }
        }
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

function Install-ErlangViaWinGet {
    <#
    .SYNOPSIS
        Installs Erlang/OTP via WinGet if not already present.

    .DESCRIPTION
        Checks 'winget-apps.json' for the required Erlang version and attempts
        to install it using WinGet.

    .OUTPUTS
        None. Throws an error if installation fails.
    #>
    [CmdletBinding()]
    param()

    Write-InfoLog -Scope "ERLANG-INSTALL" `
        -Message "Attempting to install Erlang/OTP via WinGet"

    try {
        $repositoryRoot = Get-RepositoryRoot
        $wingetAppsPath = Join-Path $repositoryRoot "winget-apps.json"

        if (-not (Test-Path -LiteralPath $wingetAppsPath)) {
            throw "winget-apps.json not found at repository root"
        }

        $wingetApps = Get-Content -LiteralPath $wingetAppsPath | ConvertFrom-Json
        $erlangPackage = $wingetApps.Sources.Packages | Where-Object { $_.PackageIdentifier -eq "Erlang.ErlangOTP" }

        if (-not $erlangPackage) {
            throw "Erlang.ErlangOTP not found in winget-apps.json"
        }

        $version = $erlangPackage.Version
        Write-InfoLog -Scope "ERLANG-INSTALL" `
            -Message "Installing Erlang.ErlangOTP version $version"

        & winget install --id Erlang.ErlangOTP --version $version --exact --accept-package-agreements --accept-source-agreements

        if ($LASTEXITCODE -ne 0) {
            throw "WinGet installation failed with code $LASTEXITCODE"
        }

        Write-InfoLog -Scope "ERLANG-INSTALL" `
            -Message "Erlang/OTP installation completed"
    }
    catch {
        Write-ErrorLog -Scope "ERLANG-INSTALL" `
            -Message "WinGet installation failed: $($_.Exception.Message)"
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
        -Message "Starting Elixir setup process"

    if (-not $(Test-RepositoryRoot)) {
        Write-ErrorLog -Scope "REPO-TEST" -Message "Repository root not found"

        throw "Repository root not found"
    }

    # Detect Erlang/OTP version
    $otpVersion = $null
    try {
        $otpVersion = Get-ErlangOtpVersion
    }
    catch {
        Write-WarningLog -Scope "SCRIPT-MAIN" `
            -Message "Erlang/OTP not found. Attempting installation..."

        Install-ErlangViaWinGet

        $otpVersion = Get-ErlangOtpVersion
    }

    $otpMajorVersion = $otpVersion.Major
    $otpFullVersion = $otpVersion.Full
    $otpBinPath = $otpVersion.BinPath

    # Query for latest compatible Elixir version
    $elixirVersion = Get-LatestElixirVersion -OtpMajorVersion $otpMajorVersion

    # Download and install Elixir
    Invoke-ElixirInstallation -ElixirVersion $elixirVersion `
        -OtpFullVersion $otpFullVersion `
        -ExistingErlangBinPath $otpBinPath

    # Update PATH for current session and system-wide
    Update-EnvironmentPath -ElixirVersion $elixirVersion `
        -OtpMajorVersion $otpMajorVersion `
        -OtpFullVersion $otpFullVersion `
        -ExistingOtpBinPath $otpBinPath

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
