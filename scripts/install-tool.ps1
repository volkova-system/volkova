<# :
@echo off
echo.
echo Error: This script must be run from a PowerShell terminal.
echo.
exit /b 1
#>

<#
.SYNOPSIS
    Installs executables from systems directory to user bin directory.

.DESCRIPTION
    This script installs executable files from the systems/ directory to the
    user's local bin directory (~/.local/bin) and updates the PATH environment
    variable to make the executable available system-wide. Supports Windows
    platform with proper PATH management and validation.

.NOTES
    Author: Richeve Bebedor
    Version: 0.0.0
    Last Modified: 2026-04-08
    Platform: Windows only
    Requirements: pwsh 7.6.0

.PARAMETER ExecutablePath
    Relative path to the executable within the systems/ directory.
    Example: sample-system/tools/windows/sample-tool.exe

.EXAMPLE
    .\install-tool.ps1 -ExecutablePath "sample-system/tools/windows/tool.exe"
    Installs the specified executable to ~/.local/bin and updates PATH.

.EXIT CODES
    0 - Success
    1 - Failure (with error message)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Executable path in systems/")]
    [ValidateNotNullOrEmpty()]
    [string]$ExecutablePath
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

function Get-RepositoryRootDirectory {
    <#
    .SYNOPSIS
        Gets the Git repository root directory path.

    .DESCRIPTION
        Determines the repository root directory using Git commands. Falls back
        to current directory if Git is not available or not in a repository.

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

    return $repositoryRoot
}

function Get-SystemsRootDirectory {
    <#
    .SYNOPSIS
        Gets the systems directory path within the repository.

    .DESCRIPTION
        Constructs the path to the systems directory by combining the
        repository root with the systems subdirectory name.

    .EXAMPLE
        Get-SystemsRootDirectory
        Returns the absolute path to the systems directory.
    #>
    [CmdletBinding()]
    param()

    [string]$repositoryRoot = Get-RepositoryRootDirectory
    [string]$systemsDirectory = Join-Path $repositoryRoot 'systems'

    return $systemsDirectory
}

function Get-InstallDirectory {
    <#
    .SYNOPSIS
        Gets or creates the user's local bin directory.

    .DESCRIPTION
        Returns the path to ~/.local/bin directory, creating it if it does not
        exist. This directory is used for installing user-specific executables.

    .EXAMPLE
        Get-InstallDirectory
        Returns the absolute path to ~/.local/bin directory.
    #>
    [CmdletBinding()]
    param()

    [string]$homeDirectory = $env:USERPROFILE
    [string]$installDirectory = Join-Path $homeDirectory '.local\bin'

    if (-not (Test-Path -LiteralPath $installDirectory)) {
        try {
            New-Item -ItemType Directory -Path $installDirectory -Force | Out-Null
            Write-InfoLog -Scope "INSTALL-DIR" `
                -Message "Created install directory: $installDirectory"
        } catch {
            throw "Failed to create install directory: $($_.Exception.Message)"
        }
    }

    return $installDirectory
}

function Resolve-SourceExecutablePath {
    <#
    .SYNOPSIS
        Resolves the full path to the source executable.

    .DESCRIPTION
        Combines the systems root directory with the provided executable path
        to create the full path to the source executable file.

    .PARAMETER ExecutablePath
        Relative path to the executable within the systems directory.

    .EXAMPLE
        Resolve-SourceExecutablePath -ExecutablePath "sample/tool.exe"
        Returns the full path to systems/sample/tool.exe
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ExecutablePath
    )

    [string]$systemsRoot = Get-SystemsRootDirectory
    [string]$normalizedPath = [System.IO.Path]::GetFullPath(
        (Join-Path $systemsRoot $ExecutablePath)
    )

    return $normalizedPath
}

function Resolve-TargetExecutablePath {
    <#
    .SYNOPSIS
        Resolves the full path to the target executable.

    .DESCRIPTION
        Combines the install directory with the executable filename to create
        the full path where the executable will be installed.

    .PARAMETER ExecutablePath
        Relative path to the executable within the systems directory.

    .EXAMPLE
        Resolve-TargetExecutablePath -ExecutablePath "sample/tool.exe"
        Returns the full path to ~/.local/bin/tool.exe
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ExecutablePath
    )

    [string]$installDirectory = Get-InstallDirectory
    [string]$executableName = Split-Path $ExecutablePath -Leaf
    [string]$targetPath = Join-Path $installDirectory $executableName

    return $targetPath
}

function Test-ExecutableExists {
    <#
    .SYNOPSIS
        Validates that the source executable exists.

    .DESCRIPTION
        Checks if the specified executable file exists in the systems directory
        and is accessible for installation.

    .PARAMETER SourcePath
        Full path to the source executable file.

    .EXAMPLE
        Test-ExecutableExists -SourcePath "C:\repo\systems\sample\tool.exe"
        Returns $true if the executable exists and is accessible.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SourcePath
    )

    if (-not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
        Write-ErrorLog -Scope "VALIDATE-EXEC" `
            -Message "Source executable not found: $SourcePath"
        return $false
    }

    Write-InfoLog -Scope "VALIDATE-EXEC" `
        -Message "Source executable validated: $SourcePath"
    return $true
}

function Install-ExecutableFile {
    <#
    .SYNOPSIS
        Copies the executable to the install directory.

    .DESCRIPTION
        Copies the source executable file to the target location in the user's
        local bin directory, preserving file permissions and attributes.

    .PARAMETER SourcePath
        Full path to the source executable file.

    .PARAMETER TargetPath
        Full path to the target installation location.

    .EXAMPLE
        Install-ExecutableFile -SourcePath "C:\src\tool.exe" -TargetPath "C:\bin\tool.exe"
        Copies the executable from source to target location.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$TargetPath
    )

    try {
        Copy-Item -LiteralPath $SourcePath -Destination $TargetPath -Force
        Write-InfoLog -Scope "INSTALL-EXEC" `
            -Message "Executable copied to: $TargetPath"
    } catch {
        throw "Failed to copy executable: $($_.Exception.Message)"
    }
}

function Update-UserPathEnvironment {
    <#
    .SYNOPSIS
        Updates the user's PATH environment variable.

    .DESCRIPTION
        Adds the install directory to the user's PATH environment variable if
        it is not already present. Updates both the current session and the
        persistent user environment.

    .PARAMETER InstallDirectory
        Directory path to add to the PATH environment variable.

    .EXAMPLE
        Update-UserPathEnvironment -InstallDirectory "C:\Users\user\.local\bin"
        Adds the directory to the user's PATH if not already present.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$InstallDirectory
    )

    try {
        $currentUserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        $pathEntries = $currentUserPath -split ';' | Where-Object { $_ -ne '' }

        if ($InstallDirectory -notin $pathEntries) {
            $newUserPath = $InstallDirectory + ';' + $currentUserPath
            [Environment]::SetEnvironmentVariable('Path', $newUserPath, 'User')

            Write-InfoLog -Scope "PATH-UPDATE" `
                -Message "Added to user PATH: $InstallDirectory"
        } else {
            Write-InfoLog -Scope "PATH-UPDATE" `
                -Message "Directory already in PATH: $InstallDirectory"
        }

        # Update current session PATH
        $currentSessionPath = $env:PATH
        $sessionEntries = $currentSessionPath -split ';' | Where-Object { $_ -ne '' }

        if ($InstallDirectory -notin $sessionEntries) {
            $env:PATH = $InstallDirectory + ';' + $currentSessionPath
            Write-InfoLog -Scope "PATH-UPDATE" `
                -Message "Updated session PATH: $InstallDirectory"
        }
    } catch {
        throw "Failed to update PATH environment: $($_.Exception.Message)"
    }
}

function Test-InstalledExecutable {
    <#
    .SYNOPSIS
        Validates that the executable was installed successfully.

    .DESCRIPTION
        Checks if the executable file exists at the target location and is
        accessible after installation.

    .PARAMETER TargetPath
        Full path to the installed executable file.

    .EXAMPLE
        Test-InstalledExecutable -TargetPath "C:\Users\user\.local\bin\tool.exe"
        Returns $true if the executable was installed successfully.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$TargetPath
    )

    if (-not (Test-Path -LiteralPath $TargetPath -PathType Leaf)) {
        Write-ErrorLog -Scope "VALIDATE-INSTALL" `
            -Message "Installed executable not found: $TargetPath"
        return $false
    }

    Write-InfoLog -Scope "VALIDATE-INSTALL" `
        -Message "Installation validated: $TargetPath"
    return $true
}

function Invoke-InstallWorkflow {
    <#
    .SYNOPSIS
        Executes the complete installation workflow.

    .DESCRIPTION
        Orchestrates the entire installation process including validation,
        file copying, and environment updates. Handles all error conditions
        and provides comprehensive logging.

    .PARAMETER ExecutablePath
        Relative path to the executable within the systems directory.

    .EXAMPLE
        Invoke-InstallWorkflow -ExecutablePath "sample-system/tools/tool.exe"
        Executes the complete installation process for the specified executable.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ExecutablePath
    )

    Write-InfoLog -Scope "INSTALL-START" `
        -Message "Starting installation: $ExecutablePath"

    # Resolve paths
    [string]$sourcePath = Resolve-SourceExecutablePath -ExecutablePath $ExecutablePath
    [string]$targetPath = Resolve-TargetExecutablePath -ExecutablePath $ExecutablePath
    [string]$installDirectory = Get-InstallDirectory

    Write-DebugLog -Scope "INSTALL-PATHS" `
        -Message "Source: $sourcePath"
    Write-DebugLog -Scope "INSTALL-PATHS" `
        -Message "Target: $targetPath"

    # Validate source executable
    if (-not (Test-ExecutableExists -SourcePath $sourcePath)) {
        throw "Source executable validation failed"
    }

    # Install executable
    Install-ExecutableFile -SourcePath $sourcePath -TargetPath $targetPath

    # Update PATH environment
    Update-UserPathEnvironment -InstallDirectory $installDirectory

    # Validate installation
    if (-not (Test-InstalledExecutable -TargetPath $targetPath)) {
        throw "Installation validation failed"
    }

    Write-InfoLog -Scope "INSTALL-COMPLETE" `
        -Message "Installation completed: $targetPath"
}

#endregion

#region Main Script Execution

Initialize-ScriptEnvironment
Assert-WindowsPlatform
Assert-PowerShellVersionStrict

try {
    Invoke-InstallWorkflow -ExecutablePath $ExecutablePath

    exit 0
} catch {
    Write-ErrorLog -Scope "SCRIPT-MAIN" `
        -Message "Installation failed: $($_.Exception.Message)"

    Write-DebugLog -Scope "SCRIPT-MAIN" `
        -Message "Stack Trace: $($_.ScriptStackTrace)"

    exit 1
}

#endregion
