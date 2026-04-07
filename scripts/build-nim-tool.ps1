<# :
@echo off
echo.
echo Error: This script must be run from a PowerShell terminal.
echo.
exit /b 1
#>

<#
.SYNOPSIS
    Build Nim tool executables for the current platform.

.DESCRIPTION
    Builds a Nim tool executable by formatting source code with nimpretty
    and compiling with nim compiler. Validates tool structure, formats
    source files, compiles to release binary, and validates the output
    executable. Supports Windows, Linux, and Darwin platforms.

.NOTES
    Author: Richeve Bebedor <richeve.bebedor+vs-scripts@gmail.com>
    Version: 0.0.0
    Last Modified: 2026-04-07
    Platform: Windows only
    Requirements: pwsh 7.6.0

.EXAMPLE
    .\build-nim-tool.ps1 build-nim sample-system/sample-tool
    Builds the sample-tool executable for the current platform.

.EXIT CODES
    0 - Success
    1 - Failure (with error message)
    2 - Build compilation error
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

$script:BuildCommand = "build-nim"
$script:ToolsDirectory = "tools"
$script:SourceDirectory = "nim/src"
$script:MainFile = "main.nim"
$script:TargetBuildDirectory = "nim/dist"
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

function Resolve-ToolSourceDirectory {
    <#
    .SYNOPSIS
        Resolves the tool source directory path.

    .DESCRIPTION
        Combines tools root with tool path and source directory to get the
        full path to the tool's source code.

    .PARAMETER ToolPath
        The tool path in format "system-name/tool-name".

    .OUTPUTS
        [string] Tool source directory path.

    .EXAMPLE
        $sourceDir = Resolve-ToolSourceDirectory -ToolPath "sample-system/sample-tool"
        Returns path to the tool's source directory.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ToolPath
    )

    $toolsRoot = Resolve-ToolsRootDirectory
    return Join-Path $toolsRoot $ToolPath $script:SourceDirectory
}

function Resolve-ToolMainFile {
    <#
    .SYNOPSIS
        Resolves the tool main file path.

    .DESCRIPTION
        Combines tool source directory with main file name to get the full
        path to the tool's main source file.

    .PARAMETER ToolPath
        The tool path in format "system-name/tool-name".

    .OUTPUTS
        [string] Tool main file path.

    .EXAMPLE
        $mainFile = Resolve-ToolMainFile -ToolPath "sample-system/sample-tool"
        Returns path to the tool's main.nim file.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ToolPath
    )

    $sourceDirectory = Resolve-ToolSourceDirectory -ToolPath $ToolPath
    return Join-Path $sourceDirectory $script:MainFile
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
        $resolvedCommand = Resolve-Command -Command "build-nim"
        Returns "build-nim" for valid commands.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command
    )

    $validCommands = @($script:BuildCommand)

    if ($Command -in $validCommands) {
        return $Command
    }

    return ""
}

function Assert-CommandValid {
    <#
    .SYNOPSIS
        Validates the build command and parameters.

    .DESCRIPTION
        Validates that the command is "build-nim" and that exactly one
        tool path parameter is provided. Throws an error for invalid
        commands or parameter counts.

    .PARAMETER Command
        The command to validate.

    .PARAMETER ToolPath
        The tool path parameter.

    .OUTPUTS
        None. Throws an error if validation fails.

    .EXAMPLE
        Assert-CommandValid -Command "build-nim" -ToolPath "sample-system/sample-tool"
        Validates the command and parameters.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(Mandatory = $true)]
        [string]$ToolPath
    )

    if ($Command -ne $script:BuildCommand) {
        throw "Invalid command: '$Command'"
    }

    if ([string]::IsNullOrWhiteSpace($ToolPath)) {
        throw "Tool path parameter is required"
    }
}

function Assert-ToolStructureValid {
    <#
    .SYNOPSIS
        Validates the tool directory structure.

    .DESCRIPTION
        Validates that all required directories and files exist for the
        specified tool, including source directory, main file, and build
        directories.

    .PARAMETER ToolPath
        The tool path to validate.

    .OUTPUTS
        None. Throws an error if validation fails.

    .EXAMPLE
        Assert-ToolStructureValid -ToolPath "sample-system/sample-tool"
        Validates the tool structure.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ToolPath
    )

    $toolSourcePath = Resolve-ToolSourceDirectory -ToolPath $ToolPath
    if (-not (Test-Path -LiteralPath $toolSourcePath)) {
        throw "Tool source directory not found: $ToolPath"
    }

    $mainFilePath = Resolve-ToolMainFile -ToolPath $ToolPath
    if (-not (Test-Path -LiteralPath $mainFilePath)) {
        throw "Tool source main file not found: $ToolPath"
    }

    $toolTargetPath = Resolve-ToolTargetBuildDirectory -ToolPath $ToolPath
    if (-not (Test-Path -LiteralPath $toolTargetPath)) {
        throw "Tool target build directory not found: $ToolPath"
    }

    $platform = Get-CurrentPlatform
    $platformBuildPath = Join-Path $toolTargetPath $platform
    if (-not (Test-Path -LiteralPath $platformBuildPath)) {
        throw "Tool target build platform directory not found: $ToolPath"
    }
}

function Assert-ExecutableValid {
    <#
    .SYNOPSIS
        Validates that the executable was created successfully.

    .DESCRIPTION
        Checks that the compiled executable file exists at the expected
        location. Throws an error if the executable is not found.

    .PARAMETER ToolPath
        The tool path to validate.

    .OUTPUTS
        None. Throws an error if validation fails.

    .EXAMPLE
        Assert-ExecutableValid -ToolPath "sample-system/sample-tool"
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
        throw "Tool executable not found: $ToolPath"
    }
}

#endregion

#region Build Functions

function Invoke-ToolSourceFormatting {
    <#
    .SYNOPSIS
        Formats Nim source files using nimpretty.

    .DESCRIPTION
        Recursively finds all .nim files in the tool source directory and
        formats them using nimpretty with 4-space indentation. Throws an
        error if formatting fails.

    .PARAMETER ToolPath
        The tool path to format.

    .OUTPUTS
        None. Formats source files in place.

    .EXAMPLE
        Invoke-ToolSourceFormatting -ToolPath "sample-system/sample-tool"
        Formats all Nim source files in the tool.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ToolPath
    )

    $sourceDirectory = Resolve-ToolSourceDirectory -ToolPath $ToolPath

    Write-InfoLog -Scope "BUILD-FORMAT" `
        -Message "Formatting Nim source files in $sourceDirectory"

    $nimFiles = Get-ChildItem -LiteralPath $sourceDirectory -Recurse `
        -Filter "*.nim" -File

    foreach ($nimFile in $nimFiles) {
        try {
            $formatOutput = & nimpretty --indent:4 $nimFile.FullName 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "Format tool source failed: $formatOutput"
            }

            Write-DebugLog -Scope "BUILD-FORMAT" `
                -Message "Formatted file: $($nimFile.Name)"
        } catch {
            Write-ErrorLog -Scope "BUILD-FORMAT" `
                -Message "Failed to format $($nimFile.Name): $($_.Exception.Message)"
            throw
        }
    }
}

function Invoke-ToolBuild {
    <#
    .SYNOPSIS
        Compiles the Nim tool to an executable.

    .DESCRIPTION
        Uses the Nim compiler to build the tool in release mode with the
        output directed to the platform-specific build directory. Throws
        an error if compilation fails.

    .PARAMETER ToolPath
        The tool path to build.

    .OUTPUTS
        None. Creates the compiled executable.

    .EXAMPLE
        Invoke-ToolBuild -ToolPath "sample-system/sample-tool"
        Compiles the tool to an executable.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ToolPath
    )

    $mainFilePath = Resolve-ToolMainFile -ToolPath $ToolPath
    $executablePath = Resolve-ExecutableToolFile -ToolPath $ToolPath

    Write-InfoLog -Scope "BUILD-COMPILE" `
        -Message "Compiling Nim tool: $ToolPath"

    try {
        $compileOutput = & nim compile -d:release "--out:$executablePath" $mainFilePath 2>&1

        if ($LASTEXITCODE -ne 0) {
            throw "Build tool failed: $compileOutput"
        }

        Write-DebugLog -Scope "BUILD-COMPILE" `
            -Message "Compilation successful: $executablePath"
    } catch {
        Write-ErrorLog -Scope "BUILD-COMPILE" `
            -Message "Failed to compile tool: $($_.Exception.Message)"
        throw
    }
}

#endregion

#region Help Functions

function Show-Usage {
    <#
    .SYNOPSIS
        Displays usage information for the build-nim-tool script.

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
    Write-Host "build-nim-tool - Build Nim tool executables"
    Write-Host ""
    Write-Host "Description:"
    Write-Host "    Builds a Nim tool executable for the current platform"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "    build-nim <tool_path>"
    Write-Host "    build-nim [global options]"
    Write-Host ""
    Write-Host "Arguments:"
    Write-Host "    tool_path    Relative path 'name-system/name-tool'"
    Write-Host "                 Parent directory must end with '-system'"
    Write-Host "                 Tool directory must end with '-tool'"
    Write-Host ""
    Write-Host "Global Options:"
    Write-Host "    -h, --help, help          Show this help message"
    Write-Host "    -v, --version, version    Show version information"
    Write-Host ""
    Write-Host "Example:"
    Write-Host "    > build-nim sample-system/sample-tool"
    Write-Host ""
    Write-Host "Output:"
    Write-Host "    tools/sample-system/sample-tool/nim/dist/$platform/sample-tool$extension"
    Write-Host ""
    Write-Host ""
}

function Show-Version {
    <#
    .SYNOPSIS
        Displays version information.

    .DESCRIPTION
        Shows the current version of the build-nim-tool script.

    .OUTPUTS
        None. Displays version information to console.

    .EXAMPLE
        Show-Version
        Displays the version information.
    #>
    [CmdletBinding()]
    param()

    Write-Host "$($script:BuildCommand) version, $($script:Version)"
}

#endregion

#region Primary Functions

function Invoke-PrimaryWorkflow {
    <#
    .SYNOPSIS
        Primary workflow implementation for building Nim tools.

    .DESCRIPTION
        Executes the complete build workflow including parameter validation,
        tool structure validation, source formatting, compilation, and
        executable validation.

    .OUTPUTS
        None. Builds the tool and reports success.

    .EXAMPLE
        Invoke-PrimaryWorkflow
        Executes the primary build workflow.
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
        Write-ErrorLog -Scope "BUILD-VALIDATE" `
            -Message "Invalid command: '$Command'"
        Show-Usage
        throw "Invalid command: '$Command'"
    }

    # Validate parameters
    Assert-CommandValid -Command $resolvedCommand -ToolPath $ToolPath

    Write-InfoLog -Scope "BUILD-START" `
        -Message "Starting build process for tool: $ToolPath"

    # Validate tool structure
    Assert-ToolStructureValid -ToolPath $ToolPath

    # Format source files
    Invoke-ToolSourceFormatting -ToolPath $ToolPath

    # Build tool
    Invoke-ToolBuild -ToolPath $ToolPath

    # Validate executable
    Assert-ExecutableValid -ToolPath $ToolPath

    $executablePath = Resolve-ExecutableToolFile -ToolPath $ToolPath
    Write-InfoLog -Scope "BUILD-SUCCESS" `
        -Message "Build completed successfully: $executablePath"
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
