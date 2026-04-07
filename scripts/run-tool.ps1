<# :
@echo off
echo.
echo Error: This script must be run from a PowerShell terminal.
echo.
exit /b 1
#>

<#
.SYNOPSIS
    Executes tool files sequentially with nested tool file support.

.DESCRIPTION
    A PowerShell implementation of the run-tool utility that executes .tool
    files line by line. Supports comments, nested tool files, PowerShell scripts,
    and shell commands. Provides cross-platform compatibility and follows SOLID
    principles for maintainability and extensibility.

.NOTES
    Author: Richeve Bebedor
    Version: 0.0.0
    Last Modified: 2026-04-07
    Platform: Windows only
    Requirements: pwsh 7.6.0

.PARAMETER ToolFilePath
    Path to the .tool file to execute. Can be relative or absolute.

.PARAMETER Help
    Display help information for the run command.

.PARAMETER Version
    Display version information.

.EXAMPLE
    .\run-tool.ps1 -ToolFilePath "./build.tool"
    Executes the build.tool file in the current directory.

.EXAMPLE
    .\run-tool.ps1 -Help
    Displays help information.

.EXIT CODES
    0 - Success
    1 - Invalid parameters or tool file not found
    2 - Command execution failure
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$Command,

    [Parameter(Mandatory = $false, Position = 1)]
    [string]$ToolFilePath
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

$script:RunCommand = "run"
$script:ToolFileExtension = '.tool'
$script:ToolsDirectory = 'tools'
$script:Version = '0.0.0'

#endregion

#region Line Classification Functions

function Get-LineType {
    <#
    .SYNOPSIS
        Classifies a line from a tool file by its content type.

    .DESCRIPTION
        Analyzes a line of text and determines whether it is empty, a comment,
        a tool file reference, or a command to execute. This classification
        drives the execution logic for processing tool files.

    .PARAMETER Line
        The line of text to classify.

    .EXAMPLE
        Get-LineType "# This is a comment"
        Returns "Comment"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Line
    )

    $trimmedLine = $Line.Trim()

    if ([string]::IsNullOrEmpty($trimmedLine)) {
        return 'Empty'
    }

    if ($trimmedLine.StartsWith('#')) {
        return 'Comment'
    }

    if ($trimmedLine.EndsWith($script:ToolFileExtension)) {
        return 'ToolFile'
    }

    if ($trimmedLine.EndsWith('.ps1')) {
        return 'PowerShellScript'
    }

    return 'Command'
}

#endregion

#region Path Resolution Functions

function Get-RepositoryRootDirectory {
    <#
    .SYNOPSIS
        Determines the root directory of the current Git repository.

    .DESCRIPTION
        Uses Git commands to locate the repository root directory. Falls back
        to the current working directory if Git is not available or if not
        in a Git repository.

    .EXAMPLE
        Get-RepositoryRootDirectory
        Returns the absolute path to the repository root.
    #>
    [CmdletBinding()]
    param()

    [string]$repositoryRoot = $PWD.Path

    $gitCommand = Get-Command -Name 'git' -ErrorAction SilentlyContinue
    if ($gitCommand) {
        try {
            $detectedRoot = (& git rev-parse --show-toplevel 2>$null)
            if ($detectedRoot -and (Test-Path -LiteralPath $detectedRoot)) {
                $message = "Detected Git repository root: $detectedRoot"
                Write-DebugLog -Scope "REPO-ROOT" -Message $message
                $repositoryRoot = $detectedRoot
            }
        } catch {
            $message = "Git root detection failed, using current directory"
            Write-DebugLog -Scope "REPO-ROOT" -Message $message
        }
    }

    return [System.IO.Path]::GetFullPath($repositoryRoot)
}

function Resolve-ToolFilePath {
    <#
    .SYNOPSIS
        Resolves a tool file path to its absolute location.

    .DESCRIPTION
        Searches for a tool file in multiple locations: relative to the
        current tool file, repository root, and current directory. Returns
        the first valid path found.

    .PARAMETER ToolFilePath
        The tool file path to resolve.

    .PARAMETER CurrentToolFile
        The path of the currently executing tool file for relative resolution.

    .EXAMPLE
        Resolve-ToolFilePath "./build.tool" "C:\repo\tools\setup.tool"
        Returns the absolute path to build.tool.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ToolFilePath,

        [Parameter(Mandatory = $false)]
        [string]$CurrentToolFile = ''
    )

    $normalizedPath = [System.IO.Path]::GetFullPath($ToolFilePath)

    # Check if already absolute and exists
    if ([System.IO.Path]::IsPathRooted($ToolFilePath) -and
        (Test-Path -LiteralPath $normalizedPath)) {
        return $normalizedPath
    }

    # Check relative to current tool file
    if (-not [string]::IsNullOrEmpty($CurrentToolFile)) {
        $currentDirectory = [System.IO.Path]::GetDirectoryName($CurrentToolFile)
        $relativePath = Join-Path $currentDirectory $ToolFilePath
        $absoluteRelativePath = [System.IO.Path]::GetFullPath($relativePath)

        if (Test-Path -LiteralPath $absoluteRelativePath) {
            return $absoluteRelativePath
        }
    }

    # Check relative to repository root
    $repositoryRoot = Get-RepositoryRootDirectory
    $repositoryPath = Join-Path $repositoryRoot $ToolFilePath
    $absoluteRepositoryPath = [System.IO.Path]::GetFullPath($repositoryPath)

    if (Test-Path -LiteralPath $absoluteRepositoryPath) {
        return $absoluteRepositoryPath
    }

    # Check relative to current directory
    $currentPath = Join-Path $PWD.Path $ToolFilePath
    $absoluteCurrentPath = [System.IO.Path]::GetFullPath($currentPath)

    if (Test-Path -LiteralPath $absoluteCurrentPath) {
        return $absoluteCurrentPath
    }

    throw "Tool file path not found: $ToolFilePath"
}

#endregion

#region Command Execution Functions

function Invoke-PowerShellScript {
    <#
    .SYNOPSIS
        Executes a PowerShell script file on Windows platform using pwsh command.

    .DESCRIPTION
        Runs a PowerShell script (.ps1) file using the pwsh command on Windows.
        The script path is resolved relative to the scripts directory and
        executed with proper error handling and logging.

    .PARAMETER ScriptPath
        The relative path to the PowerShell script file to execute.

    .EXAMPLE
        Invoke-PowerShellScript "build-helper.ps1"
        Executes the build-helper.ps1 script from the scripts directory.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ScriptPath
    )

    Write-InfoLog -Scope "PS1-EXEC" -Message "Executing PowerShell script: $ScriptPath"

    # Resolve script path relative to the scripts directory
    $scriptsDirectory = $PSScriptRoot
    $absoluteScriptPath = Join-Path $scriptsDirectory $ScriptPath
    $resolvedScriptPath = [System.IO.Path]::GetFullPath($absoluteScriptPath)

    if (-not (Test-Path -LiteralPath $resolvedScriptPath)) {
        throw "PowerShell script not found: $resolvedScriptPath"
    }

    try {
        # Execute using pwsh command for Windows platform
        $pwshCommand = "pwsh -File `"$resolvedScriptPath`""

        Write-DebugLog -Scope "PS1-EXEC" -Message "Executing: $pwshCommand"

        $result = Invoke-Expression $pwshCommand

        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
            throw "PowerShell script failed with exit code: $LASTEXITCODE"
        }

        Write-DebugLog -Scope "PS1-EXEC" `
            -Message "PowerShell script completed successfully"

        return $result
    } catch {
        $errorMessage = "PowerShell script execution failed: $($_.Exception.Message)"
        Write-ErrorLog -Scope "PS1-EXEC" -Message $errorMessage

        throw $errorMessage
    }
}

function Invoke-ShellCommand {
    <#
    .SYNOPSIS
        Executes a shell command with proper error handling.

    .DESCRIPTION
        Runs a command using PowerShell's native execution capabilities.
        Provides detailed error reporting and maintains exit code handling
        for proper error propagation.

    .PARAMETER Command
        The command string to execute.

    .EXAMPLE
        Invoke-ShellCommand "npm install"
        Executes the npm install command.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Command
    )

    Write-InfoLog -Scope "SHELL-EXEC" -Message "Executing: $Command"

    try {
        $result = Invoke-Expression $Command

        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
            throw "Command failed with exit code: $LASTEXITCODE"
        }

        Write-DebugLog -Scope "SHELL-EXEC" `
            -Message "Command completed successfully"

        return $result
    } catch {
        $errorMessage = "Command execution failed: $($_.Exception.Message)"
        Write-ErrorLog -Scope "SHELL-EXEC" -Message $errorMessage

        throw $errorMessage
    }
}

function Invoke-ToolFileExecution {
    <#
    .SYNOPSIS
        Executes a tool file by processing each line sequentially.

    .DESCRIPTION
        Reads a tool file and processes each line according to its type.
        Handles comments, nested tool files, and shell commands. Provides
        recursive execution for nested tool files.

    .PARAMETER ToolFilePath
        The absolute path to the tool file to execute.

    .EXAMPLE
        Invoke-ToolFileExecution "C:\repo\tools\build.tool"
        Executes the build.tool file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ToolFilePath
    )

    Write-InfoLog -Scope "TOOL-EXEC" -Message "Processing tool file: $ToolFilePath"

    if (-not (Test-Path -LiteralPath $ToolFilePath)) {
        throw "Tool file not found: $ToolFilePath"
    }

    try {
        $fileContent = Get-Content -LiteralPath $ToolFilePath -ErrorAction Stop
        $lineNumber = 0

        foreach ($line in $fileContent) {
            $lineNumber++
            $lineType = Get-LineType -Line $line

            Write-DebugLog -Scope "TOOL-EXEC" `
                -Message "Line $lineNumber ($lineType): $line"

            switch ($lineType) {
                'Empty' {
                    continue
                }
                'Comment' {
                    continue
                }
                'ToolFile' {
                    $nestedToolPath = Resolve-ToolFilePath `
                        -ToolFilePath $line.Trim() `
                        -CurrentToolFile $ToolFilePath

                    Invoke-ToolFileExecution -ToolFilePath $nestedToolPath
                }
                'PowerShellScript' {
                    Invoke-PowerShellScript -ScriptPath $line.Trim()
                }
                'Command' {
                    Invoke-ShellCommand -Command $line.Trim()
                }
            }
        }

        Write-InfoLog -Scope "TOOL-EXEC" `
            -Message "Tool file completed: $ToolFilePath"
    } catch {
        $errorMessage = "Tool file execution failed: $($_.Exception.Message)"
        Write-ErrorLog -Scope "TOOL-EXEC" -Message $errorMessage

        throw $errorMessage
    }
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
        $resolvedCommand = Resolve-Command -Command "run"
        Returns "run" for valid commands.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command
    )

    $validCommands = @($script:RunCommand)

    if ($Command -in $validCommands) {
        return $Command
    }

    return ""
}

function Assert-CommandValid {
    <#
    .SYNOPSIS
        Validates the run command and parameters.

    .DESCRIPTION
        Validates that the command is "run" and that exactly one
        tool file path parameter is provided. Throws an error for invalid
        commands or parameter counts.

    .PARAMETER Command
        The command to validate.

    .PARAMETER ToolFilePath
        The tool file path parameter.

    .OUTPUTS
        None. Throws an error if validation fails.

    .EXAMPLE
        Assert-CommandValid -Command "run" -ToolFilePath "build.tool"
        Validates the command and parameters.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(Mandatory = $true)]
        [string]$ToolFilePath
    )

    if ($Command -ne $script:RunCommand) {
        throw "Invalid command: '$Command'"
    }

    if ([string]::IsNullOrWhiteSpace($ToolFilePath)) {
        throw "Tool file path parameter is required"
    }
}

function Test-ToolFileExtension {
    <#
    .SYNOPSIS
        Validates that a file has the correct tool file extension.

    .DESCRIPTION
        Checks if the provided file path ends with the expected .tool
        extension. This validation ensures only valid tool files are
        processed by the execution engine.

    .PARAMETER FilePath
        The file path to validate.

    .EXAMPLE
        Test-ToolFileExtension "./build.tool"
        Returns $true if the file has .tool extension.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath
    )

    return $FilePath.EndsWith($script:ToolFileExtension,
        [System.StringComparison]::OrdinalIgnoreCase)
}

function Assert-ToolFileExists {
    <#
    .SYNOPSIS
        Validates that a tool file exists and is accessible.

    .DESCRIPTION
        Performs comprehensive validation of a tool file including extension
        check and file existence verification. Throws descriptive errors
        for validation failures.

    .PARAMETER ToolFilePath
        The tool file path to validate.

    .EXAMPLE
        Assert-ToolFileExists "./build.tool"
        Validates the build.tool file exists and has correct extension.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ToolFilePath
    )

    if (-not (Test-ToolFileExtension -FilePath $ToolFilePath)) {
        throw "Invalid tool file extension: $ToolFilePath"
    }

    $resolvedPath = Resolve-ToolFilePath -ToolFilePath $ToolFilePath

    if (-not (Test-Path -LiteralPath $resolvedPath)) {
        throw "Tool file not found: $resolvedPath"
    }

    Write-DebugLog -Scope "TOOL-VALIDATE" `
        -Message "Tool file validated: $resolvedPath"
}

#endregion

#region Help and Version Functions

function Show-Usage {
    <#
    .SYNOPSIS
        Displays usage information for the run-tool script.

    .DESCRIPTION
        Provides comprehensive help information including description,
        usage patterns, arguments, options, format specifications,
        and examples for using the run-tool script.
    #>
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host ""
    Write-Host "run-tool - Run tool files"
    Write-Host ""
    Write-Host "Description:"
    Write-Host "    Executes a .tool file sequentially"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "    run <tool_file_path>"
    Write-Host "    run [global options]"
    Write-Host ""
    Write-Host "Arguments:"
    Write-Host "    tool_file_path    Path to a .tool file"
    Write-Host ""
    Write-Host "Global Options:"
    Write-Host "    -h, --help, help          Show this help message"
    Write-Host "    -v, --version, version    Show version information"
    Write-Host ""
    Write-Host "Format:"
    Write-Host "    # comment line          (ignored)"
    Write-Host "    ./path/to/other.tool    (nested tool file, executed first)"
    Write-Host "    script.ps1              (PowerShell script, executed with pwsh on Windows)"
    Write-Host "    <command expression>    (executed on compatible shell)"
    Write-Host ""
    Write-Host "Example:"
    Write-Host "    run ./tools/prototype-system/run-tool/build.tool"
    Write-Host ""
    Write-Host ""
}

function Show-Version {
    <#
    .SYNOPSIS
        Displays version information for the run-tool script.

    .DESCRIPTION
        Shows the current version number of the run-tool script in a
        standardized format for version identification and compatibility
        checking.
    #>
    [CmdletBinding()]
    param()

    Write-Host "$($script:RunCommand) version, $($script:Version)"
}

#endregion

#region Primary Functions

function Invoke-PrimaryWorkflow {
    <#
    .SYNOPSIS
        Primary workflow implementation for tool execution.

    .DESCRIPTION
        Orchestrates the main execution flow including parameter validation,
        tool file resolution, and execution. Handles all primary use cases
        including help display, version information, and tool execution.
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
        Write-ErrorLog -Scope "RUN-VALIDATE" `
            -Message "Invalid command: '$Command'"
        Show-Usage
        throw "Invalid command: '$Command'"
    }

    # Validate parameters
    Assert-CommandValid -Command $resolvedCommand -ToolFilePath $ToolFilePath

    Write-InfoLog -Scope "RUN-START" `
        -Message "Starting tool execution for: $ToolFilePath"

    # Validate and resolve tool file
    try {
        Assert-ToolFileExists -ToolFilePath $ToolFilePath
        $resolvedToolPath = Resolve-ToolFilePath -ToolFilePath $ToolFilePath

        Write-InfoLog -Scope "TOOL-START" `
            -Message "Starting tool execution: $resolvedToolPath"

        # Execute the tool file
        Invoke-ToolFileExecution -ToolFilePath $resolvedToolPath

        Write-InfoLog -Scope "TOOL-COMPLETE" `
            -Message "Tool execution completed successfully: $resolvedToolPath"
    } catch {
        Write-ErrorLog -Scope "TOOL-ERROR" `
            -Message "Tool execution failed: $($_.Exception.Message)"
        throw
    }
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
