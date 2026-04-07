<# :
@echo off
echo.
echo Error: This script must be run from a PowerShell terminal.
echo.
exit /b 1
#>

<#
.SYNOPSIS
    Install Nim tool executables for the current platform.

.DESCRIPTION
    Installs a built Nim tool executable by copying it to the user's local
    bin directory and updating the PATH environment variable. Validates tool
    structure, copies executable to install directory, updates Windows PATH
    via registry, and validates the installed executable. Supports Windows
    platform with automatic PATH management.

.NOTES
    Author: Richeve Bebedor <richeve.bebedor+vs-scripts@gmail.com>
    Version: 0.0.0
    Last Modified: 2026-04-07
    Platform: Windows only
    Requirements: pwsh 7.6.0

.EXAMPLE
    .\install-nim-tool.ps1 install-nim sample-system/sample-tool
    Installs the sample-tool executable as a terminal command.

.EXIT CODES
    0 - Success
    1 - Failure (with error message)
    2 - Installation error
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$Command,

    [Parameter(Mandatory = $false, Position = 1)]
    [string]$ToolPath
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

#region Configuration

$script:InstallCommand = "install-nim"
$script:ToolsDirectory = "tools"
$script:TargetBuildDirectory = "nim/dist"
$script:InstallDirectory = Join-Path $env:USERPROFILE ".local" "bin"
$script:Version = "0.0.0"

#endregion

#region Utility Functions

function Get-CurrentPlatform {
    <#
    .SYNOPSIS
        Gets the current platform name.

    .DESCRIPTION
        Determines the current platform (windows, linux, darwin) based on
        PowerShell platform detection. Returns standardized platform names
        for use in build directory structure.

    .OUTPUTS
        [string] Platform name (windows, linux, or darwin).

    .EXAMPLE
        $platform = Get-CurrentPlatform
        Returns "windows" on Windows systems.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if ($IsWindows -or $PSVersionTable.Platform -eq 'Win32NT') {
        return "windows"
    } elseif ($IsLinux) {
        return "linux"
    } elseif ($IsMacOS) {
        return "darwin"
    } else {
        throw "Unsupported platform: $($PSVersionTable.Platform)"
    }
}

function Get-RepositoryRootDirectory {
    <#
    .SYNOPSIS
        Gets the repository root directory path.

    .DESCRIPTION
        Uses git rev-parse to determine the repository root directory.
        Throws an error if git is not available or if not in a git
        repository.

    .OUTPUTS
        [string] Repository root directory path.

    .EXAMPLE
        $repoRoot = Get-RepositoryRootDirectory
        Returns the absolute path to the repository root.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    try {
        $gitOutput = & git rev-parse --show-toplevel 2>$null
        if ($LASTEXITCODE -eq 0 -and $gitOutput) {
            return $gitOutput.Trim()
        }

        throw "Cannot determine repository root directory path"
    } catch {
        Write-ErrorLog -Scope "REPO-ROOT" `
            -Message "Failed to get repository root: $($_.Exception.Message)"
        throw
    }
}

function Get-InstallDirectory {
    <#
    .SYNOPSIS
        Gets the install directory path, creating it if necessary.

    .DESCRIPTION
        Returns the user's local bin directory path and creates the
        directory if it doesn't exist. This is where tool executables
        will be installed.

    .OUTPUTS
        [string] Install directory path.

    .EXAMPLE
        $installDir = Get-InstallDirectory
        Returns the path to ~/.local/bin directory.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if (-not (Test-Path -LiteralPath $script:InstallDirectory)) {
        try {
            New-Item -ItemType Directory -Path $script:InstallDirectory `
                -Force | Out-Null
            Write-DebugLog -Scope "INSTALL-DIR" `
                -Message "Created install directory: $script:InstallDirectory"
        } catch {
            Write-ErrorLog -Scope "INSTALL-DIR" `
                -Message "Failed to create install directory: $($_.Exception.Message)"
            throw
        }
    }

    return $script:InstallDirectory
}

function Resolve-ToolsRootDirectory {
    <#
    .SYNOPSIS
        Resolves the tools root directory path.

    .DESCRIPTION
        Combines repository root with tools directory to get the full path
        to the tools directory.

    .OUTPUTS
        [string] Tools root directory path.

    .EXAMPLE
        $toolsRoot = Resolve-ToolsRootDirectory
        Returns the absolute path to the tools directory.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $repositoryRoot = Get-RepositoryRootDirectory
    return Join-Path $repositoryRoot $script:ToolsDirectory
}

function Resolve-ToolTargetBuildDirectory {
    <#
    .SYNOPSIS
        Resolves the tool target build directory path.

    .DESCRIPTION
        Combines tools root with tool path and target build directory to
        get the full path to the tool's build output directory.

    .PARAMETER ToolPath
        The tool path in format "system-name/tool-name".

    .OUTPUTS
        [string] Tool target build directory path.

    .EXAMPLE
        $buildDir = Resolve-ToolTargetBuildDirectory -ToolPath "sample-system/sample-tool"
        Returns path to the tool's build directory.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ToolPath
    )

    $toolsRoot = Resolve-ToolsRootDirectory
    return Join-Path $toolsRoot $ToolPath $script:TargetBuildDirectory
}

function Resolve-ExecutableExtension {
    <#
    .SYNOPSIS
        Resolves the executable extension for the current platform.

    .DESCRIPTION
        Returns the appropriate executable extension (.exe for Windows,
        empty string for Unix-like systems).

    .OUTPUTS
        [string] Executable extension.

    .EXAMPLE
        $extension = Resolve-ExecutableExtension
        Returns ".exe" on Windows, "" on Unix-like systems.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $platform = Get-CurrentPlatform
    if ($platform -eq "windows") {
        return ".exe"
    } else {
        return ""
    }
}

function Resolve-ExecutableToolFile {
    <#
    .SYNOPSIS
        Resolves the executable tool file path.

    .DESCRIPTION
        Combines tool target build directory, platform, and tool name to
        get the full path to the compiled executable.

    .PARAMETER ToolPath
        The tool path in format "system-name/tool-name".

    .OUTPUTS
        [string] Executable tool file path.

    .EXAMPLE
        $executable = Resolve-ExecutableToolFile -ToolPath "sample-system/sample-tool"
        Returns path to the compiled executable.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ToolPath
    )

    $targetBuildDirectory = Resolve-ToolTargetBuildDirectory -ToolPath $ToolPath
    $platform = Get-CurrentPlatform
    $buildDirectory = Join-Path $targetBuildDirectory $platform
    $toolName = Split-Path $ToolPath -Leaf
    $executableExtension = Resolve-ExecutableExtension
    $executableFile = $toolName + $executableExtension

    return Join-Path $buildDirectory $executableFile
}

#endregion

#region Validation Functions

function Test-HelpFlag {
    <#
    .SYNOPSIS
        Tests if a parameter is a help flag.

    .DESCRIPTION
        Checks if the provided parameter matches any of the recognized help
        flag patterns (-h, --help, help).

    .PARAMETER Flag
        The parameter to test.

    .OUTPUTS
        [bool] True if the parameter is a help flag, false otherwise.

    .EXAMPLE
        $isHelp = Test-HelpFlag -Flag "--help"
        Returns $true for help flags.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Flag
    )

    return $Flag -in @("-h", "--help", "help")
}

function Test-VersionFlag {
    <#
    .SYNOPSIS
        Tests if a parameter is a version flag.

    .DESCRIPTION
        Checks if the provided parameter matches any of the recognized
        version flag patterns (-v, --version, version).

    .PARAMETER Flag
        The parameter to test.

    .OUTPUTS
        [bool] True if the parameter is a version flag, false otherwise.

    .EXAMPLE
        $isVersion = Test-VersionFlag -Flag "--version"
        Returns $true for version flags.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Flag
    )

    return $Flag -in @("-v", "--version", "version")
}

function Resolve-Command {
    <#
    .SYNOPSIS
        Resolves and validates a command.

    .DESCRIPTION
        Checks if the provided command is valid and returns the normalized
        command name. Returns empty string for invalid commands.

    .PARAMETER Command
        The command to resolve.

    .OUTPUTS
        [string] Resolved command name or empty string if invalid.

    .EXAMPLE
        $resolvedCommand = Resolve-Command -Command "install-nim"
        Returns "install-nim" for valid commands.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command
    )

    $validCommands = @($script:InstallCommand)

    if ($Command -in $validCommands) {
        return $Command
    }

    return ""
}

function Assert-CommandValid {
    <#
    .SYNOPSIS
        Validates the install command and parameters.

    .DESCRIPTION
        Validates that the command is "install-nim" and that exactly one
        tool path parameter is provided. Throws an error for invalid
        commands or parameter counts.

    .PARAMETER Command
        The command to validate.

    .PARAMETER ToolPath
        The tool path parameter.

    .OUTPUTS
        None. Throws an error if validation fails.

    .EXAMPLE
        Assert-CommandValid -Command "install-nim" -ToolPath "sample-system/sample-tool"
        Validates the command and parameters.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(Mandatory = $true)]
        [string]$ToolPath
    )

    if ($Command -ne $script:InstallCommand) {
        throw "Invalid command: '$Command'"
    }

    if ([string]::IsNullOrWhiteSpace($ToolPath)) {
        throw "Tool path parameter is required"
    }
}

function Assert-ExecutableExists {
    <#
    .SYNOPSIS
        Validates that the tool executable exists.

    .DESCRIPTION
        Checks that the compiled executable file exists at the expected
        location. Throws an error if the executable is not found.

    .PARAMETER ToolPath
        The tool path to validate.

    .OUTPUTS
        None. Throws an error if validation fails.

    .EXAMPLE
        Assert-ExecutableExists -ToolPath "sample-system/sample-tool"
        Validates the compiled executable exists.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ToolPath
    )

    $executablePath = Resolve-ExecutableToolFile -ToolPath $ToolPath
    if (-not (Test-Path -LiteralPath $executablePath)) {
        throw "Tool executable not found: $executablePath"
    }
}

function Assert-InstallDirectoryExists {
    <#
    .SYNOPSIS
        Validates that the install directory exists.

    .DESCRIPTION
        Checks that the install directory exists and is accessible.
        Throws an error if the directory is not found.

    .OUTPUTS
        None. Throws an error if validation fails.

    .EXAMPLE
        Assert-InstallDirectoryExists
        Validates the install directory exists.
    #>
    [CmdletBinding()]
    param()

    $installDirectory = Get-InstallDirectory
    if (-not (Test-Path -LiteralPath $installDirectory)) {
        throw "Install directory not found: $installDirectory"
    }
}

function Assert-InstalledExecutableValid {
    <#
    .SYNOPSIS
        Validates that the executable was installed successfully.

    .DESCRIPTION
        Checks that the installed executable file exists at the install
        location. Throws an error if the executable is not found.

    .PARAMETER ToolPath
        The tool path to validate.

    .OUTPUTS
        None. Throws an error if validation fails.

    .EXAMPLE
        Assert-InstalledExecutableValid -ToolPath "sample-system/sample-tool"
        Validates the installed executable exists.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ToolPath
    )

    $installDirectory = Get-InstallDirectory
    $toolName = Split-Path $ToolPath -Leaf
    $executableExtension = Resolve-ExecutableExtension
    $installedExecutable = Join-Path $installDirectory ($toolName + $executableExtension)

    if (-not (Test-Path -LiteralPath $installedExecutable)) {
        throw "Installed tool not found: $installedExecutable"
    }
}

#endregion

#region Installation Functions

function Invoke-ExecutableInstallation {
    <#
    .SYNOPSIS
        Installs the tool executable to the install directory.

    .DESCRIPTION
        Copies the compiled executable from the build directory to the
        user's local bin directory and updates the Windows PATH environment
        variable to include the install directory.

    .PARAMETER ToolPath
        The tool path to install.

    .OUTPUTS
        [string] Path to the installed executable.

    .EXAMPLE
        $installedPath = Invoke-ExecutableInstallation -ToolPath "sample-system/sample-tool"
        Installs the tool and returns the installed path.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ToolPath
    )

    $executablePath = Resolve-ExecutableToolFile -ToolPath $ToolPath
    $installDirectory = Get-InstallDirectory
    $toolName = Split-Path $ToolPath -Leaf
    $executableExtension = Resolve-ExecutableExtension
    $targetPath = Join-Path $installDirectory ($toolName + $executableExtension)

    Write-InfoLog -Scope "INSTALL-COPY" `
        -Message "Copying executable to install directory"

    try {
        Copy-Item -LiteralPath $executablePath -Destination $targetPath -Force
        Write-DebugLog -Scope "INSTALL-COPY" `
            -Message "Copied $executablePath to $targetPath"
    } catch {
        Write-ErrorLog -Scope "INSTALL-COPY" `
            -Message "Failed to copy executable: $($_.Exception.Message)"
        throw
    }

    # Update Windows PATH environment variable
    try {
        Invoke-WindowsPathUpdate -InstallDirectory $installDirectory
    } catch {
        Write-ErrorLog -Scope "INSTALL-PATH" `
            -Message "Failed to update PATH: $($_.Exception.Message)"
        throw
    }

    return $targetPath
}

function Invoke-WindowsPathUpdate {
    <#
    .SYNOPSIS
        Updates the Windows PATH environment variable.

    .DESCRIPTION
        Adds the install directory to the user's PATH environment variable
        if it's not already present. Updates both the registry and the
        current session PATH.

    .PARAMETER InstallDirectory
        The directory to add to PATH.

    .OUTPUTS
        None. Updates the PATH environment variable.

    .EXAMPLE
        Invoke-WindowsPathUpdate -InstallDirectory "C:\Users\user\.local\bin"
        Adds the directory to the user's PATH.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$InstallDirectory
    )

    Write-InfoLog -Scope "INSTALL-PATH" `
        -Message "Updating Windows PATH environment variable"

    try {
        $currentUserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        if (-not $currentUserPath) {
            $currentUserPath = ""
        }

        $pathEntries = $currentUserPath -split ';' | Where-Object { $_ -ne '' }

        if ($InstallDirectory -notin $pathEntries) {
            $newUserPath = $InstallDirectory + ';' + $currentUserPath
            [Environment]::SetEnvironmentVariable('Path', $newUserPath, 'User')

            Write-InfoLog -Scope "INSTALL-PATH" `
                -Message "Added install directory to user PATH"
        } else {
            Write-InfoLog -Scope "INSTALL-PATH" `
                -Message "Install directory already in user PATH"
        }

        # Update current session PATH
        $currentSessionPath = $env:PATH
        $sessionPathEntries = $currentSessionPath -split ';' | Where-Object { $_ -ne '' }

        if ($InstallDirectory -notin $sessionPathEntries) {
            $env:PATH = $InstallDirectory + ';' + $currentSessionPath
            Write-DebugLog -Scope "INSTALL-PATH" `
                -Message "Updated current session PATH"
        }

    } catch {
        Write-ErrorLog -Scope "INSTALL-PATH" `
            -Message "Failed to update PATH: $($_.Exception.Message)"
        throw
    }
}

#endregion

#region Help Functions

function Show-Usage {
    <#
    .SYNOPSIS
        Displays usage information for the install-nim-tool script.

    .DESCRIPTION
        Shows comprehensive usage information including description,
        syntax, arguments, options, and examples.

    .OUTPUTS
        None. Displays usage information to console.

    .EXAMPLE
        Show-Usage
        Displays the help information.
    #>
    [CmdletBinding()]
    param()

    $platform = Get-CurrentPlatform
    $extension = Resolve-ExecutableExtension

    Write-Host ""
    Write-Host ""
    Write-Host "install-nim-tool - Install Nim tool executables"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "    install-nim <tool_path>"
    Write-Host ""
    Write-Host "Description:"
    Write-Host "    Installs a built Nim tool executable for the current platform"
    Write-Host "    as a terminal command available to all users"
    Write-Host ""
    Write-Host "Arguments:"
    Write-Host "    tool_path    Relative path 'name-system/name-tool'"
    Write-Host "                 Parent directory must end with '-system'"
    Write-Host "                 Tool directory must end with '-tool'"
    Write-Host ""
    Write-Host "Example:"
    Write-Host "    install-nim sample-system/sample-tool"
    Write-Host ""
    Write-Host "Installs:"
    Write-Host "    tools/sample-system/sample-tool/nim/dist/$platform/sample-tool$extension"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "    -h, --help, help    Show this help message"
    Write-Host "    -v, --version       Show version information"
    Write-Host ""
    Write-Host ""
}

function Show-Version {
    <#
    .SYNOPSIS
        Displays version information.

    .DESCRIPTION
        Shows the current version of the install-nim-tool script.

    .OUTPUTS
        None. Displays version information to console.

    .EXAMPLE
        Show-Version
        Displays the version information.
    #>
    [CmdletBinding()]
    param()

    Write-Host "$($script:InstallCommand) version $($script:Version)"
}

#endregion

#region Primary Functions

function Invoke-PrimaryWorkflow {
    <#
    .SYNOPSIS
        Primary workflow implementation for installing Nim tools.

    .DESCRIPTION
        Executes the complete installation workflow including parameter
        validation, executable validation, installation, PATH updates,
        and installed executable validation.

    .OUTPUTS
        None. Installs the tool and reports success.

    .EXAMPLE
        Invoke-PrimaryWorkflow
        Executes the primary installation workflow.
    #>
    [CmdletBinding()]
    param()

    # Handle help and version flags
    if (Test-HelpFlag -Flag $Command) {
        Show-Usage
        return
    }

    if (Test-VersionFlag -Flag $Command) {
        Show-Version
        return
    }

    # Validate command
    $resolvedCommand = Resolve-Command -Command $Command
    if ([string]::IsNullOrEmpty($resolvedCommand)) {
        Write-ErrorLog -Scope "INSTALL-VALIDATE" `
            -Message "Invalid command: '$Command'"
        Show-Usage
        throw "Invalid command: '$Command'"
    }

    # Validate parameters
    Assert-CommandValid -Command $resolvedCommand -ToolPath $ToolPath

    Write-InfoLog -Scope "INSTALL-START" `
        -Message "Starting installation process for tool: $ToolPath"

    # Validate executable exists
    Assert-ExecutableExists -ToolPath $ToolPath

    # Validate install directory
    Assert-InstallDirectoryExists

    # Install executable
    $installedPath = Invoke-ExecutableInstallation -ToolPath $ToolPath

    # Validate installed executable
    Assert-InstalledExecutableValid -ToolPath $ToolPath

    Write-InfoLog -Scope "INSTALL-SUCCESS" `
        -Message "Installation completed successfully: $installedPath"
}

#endregion

#region Main Script Execution

Initialize-ScriptEnvironment
Assert-WindowsPlatform
Assert-PowerShellVersionStrict

try {
    # Handle no parameters case
    if ([string]::IsNullOrWhiteSpace($Command)) {
        Show-Usage
        exit 1
    }

    Invoke-PrimaryWorkflow

    exit 0
} catch {
    Write-ErrorLog -Scope "SCRIPT-MAIN" `
        -Message "Failed: $($_.Exception.Message)"

    Write-DebugLog -Scope "SCRIPT-MAIN" `
        -Message "Stack Trace: $($_.ScriptStackTrace)"

    exit 1
}

#endregion
