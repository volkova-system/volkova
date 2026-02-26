<# :
@echo off
echo.
echo Error: This script must be run from a PowerShell terminal.
echo.
exit /b 1
#>

<#
.SYNOPSIS
    Stops the TerminusDB Docker container gracefully.

.DESCRIPTION
    Stops the TerminusDB Docker container using docker-compose down with
    graceful shutdown timeout. If graceful shutdown times out, forces
    stop using docker stop -t 0. Includes proper error handling and
    logging.

.NOTES
    Author: TerminusDB Team
    Version: 0.0.0
    Last Modified: 2026-01-26
    Platform: Windows only
    Requirements: pwsh 7.5.4, Docker, docker-compose

.EXAMPLE
    .\stop-terminusdb.ps1
    Stops the TerminusDB container gracefully.

.EXAMPLE
    # Run from project root directory
    cd C:\path\to\project
    .\scripts\stop-terminusdb.ps1
    Stops the TerminusDB container with graceful shutdown timeout.

.EXAMPLE
    # Verify container is stopped after stopping
    .\stop-terminusdb.ps1
    docker ps --filter "name=terminusdb-service"
    Stops the container and verifies it's no longer running.

.EXIT CODES
    0 - Success (container stopped or not running)
    1 - Failure (with error message)
#>

[CmdletBinding()]
param()

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

#region Helper Functions

function Get-RepositoryRoot {
    <#
    .SYNOPSIS
        Gets the repository root directory.

    .DESCRIPTION
        Determines the repository root directory by checking for git repository.

    .OUTPUTS
        System.String. Returns the absolute path to the repository root.

    .EXAMPLE
        # Returns the repository root directory path.
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

function Test-DockerComposeFile {
    <#
    .SYNOPSIS
        Validates Docker Compose file exists and is readable.

    .DESCRIPTION
        Checks if the Docker Compose file exists at the expected path
        and is readable. Returns boolean result.

    .PARAMETER Path
        Full path to the Docker Compose file.

    .OUTPUTS
        [bool] $true if file exists and readable, $false otherwise.

    .ERRORS
        Returns $false if file does not exist or is not readable.
        Does not throw exceptions; errors are handled internally.

    .EXAMPLE
        if (Test-DockerComposeFile -Path $composePath) {
            Write-InfoLog -Scope "DOCKER-COMPOSE" -Message "File valid"
        }
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    try {
        # Check if file exists as a leaf item (not directory)
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            return $false
        }

        # Attempt to read file content to verify readability
        [void](Get-Content -LiteralPath $Path -ErrorAction Stop)
        return $true
    }
    catch {
        # File exists but is not readable
        return $false
    }
}

function Test-DockerAvailable {
    <#
    .SYNOPSIS
        Verifies Docker is installed and daemon is running.

    .DESCRIPTION
        Checks Docker installation via docker --version and verifies
        daemon connectivity via docker ps. Returns boolean result.

    .OUTPUTS
        [bool] $true if Docker available, $false otherwise.

    .ERRORS
        Returns $false if Docker is not installed, not in PATH, or
        daemon is not running. Does not throw exceptions.

    .EXAMPLE
        if (Test-DockerAvailable) {
            Write-InfoLog -Scope "DOCKER-CHECK" -Message "Docker ready"
        }
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    try {
        # Check if Docker command exists and returns version info
        $version = & docker --version 2>$null
        if ([string]::IsNullOrEmpty($version)) {
            return $false
        }

        # Test daemon connectivity by listing containers
        # If daemon not running, docker ps will fail
        & docker ps -q 2>$null | Out-Null
        return $LASTEXITCODE -eq 0
    }
    catch {
        # Docker command failed or not found
        return $false
    }
}

function Test-ContainerRunning {
    <#
    .SYNOPSIS
        Checks if a container is currently running.

    .DESCRIPTION
        Uses docker ps to verify if a container with the specified name
        is running. Handles multiple containers with similar names.

    .PARAMETER ContainerName
        Name of the container to check.

    .OUTPUTS
        [bool] $true if running, $false otherwise.

    .ERRORS
        Returns $false if container is not running or if docker ps
        command fails. Does not throw exceptions.

    .EXAMPLE
        if (Test-ContainerRunning -ContainerName "terminusdb-service") {
            Write-InfoLog -Scope "CONTAINER-CHECK" -Message "Running"
        }
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ContainerName
    )

    try {
        $running = & docker ps --filter "name=$ContainerName" `
            --format "{{.Names}}" 2>$null

        return -not [string]::IsNullOrEmpty($running)
    }
    catch {
        return $false
    }
}

function Stop-ContainerGracefully {
    <#
    .SYNOPSIS
        Stops container with graceful timeout and force stop fallback.

    .DESCRIPTION
        Executes docker-compose down with graceful shutdown timeout.
        If timeout exceeded, forces stop using docker stop -t 0. Logs
        warnings for forced termination.

    .PARAMETER ComposePath
        Full path to the docker-compose.yml file.

    .PARAMETER TimeoutSeconds
        Seconds to wait for graceful shutdown (default: 30).

    .OUTPUTS
        [int] Exit code (0 for success, 1 for failure).

    .ERRORS
        Returns 1 if docker-compose down fails, force stop fails, or
        container fails to stop. Logs error details before returning.

    .EXAMPLE
        $exitCode = Stop-ContainerGracefully -ComposePath $composePath
        if ($exitCode -eq 0) {
            Write-InfoLog -Scope "CONTAINER-STOP" -Message "Stopped"
        }
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ComposePath,

        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 30
    )

    $composeDir = Split-Path -Parent $ComposePath

    try {
        # Change to compose directory for docker-compose execution
        Push-Location $composeDir

        Write-InfoLog -Scope "CONTAINER-STOP" `
            -Message "Stopping container gracefully"

        # Execute docker-compose down to gracefully stop container
        # This sends SIGTERM to allow application cleanup
        $output = & docker-compose -f $ComposePath down 2>&1

        # Check exit code from docker-compose command
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorLog -Scope "CONTAINER-STOP" `
                -Message "docker-compose down failed: $output"
            return 1
        }

        # Wait for graceful shutdown with timeout loop
        # Check container status every second up to timeout
        $elapsed = 0
        while ($elapsed -lt $TimeoutSeconds) {
            if (-not (Test-ContainerRunning -ContainerName `
                "terminusdb-service")) {
                Write-InfoLog -Scope "CONTAINER-STOP" `
                    -Message "Container stopped gracefully"
                return 0
            }

            Start-Sleep -Seconds 1
            $elapsed++
        }

        # Force stop if graceful shutdown timeout exceeded
        # Use docker stop -t 0 for immediate termination
        Write-WarningLog -Scope "CONTAINER-STOP" `
            -Message "Graceful shutdown timeout, forcing stop"

        $forceOutput = & docker stop -t 0 terminusdb-service 2>&1

        # Check exit code from force stop command
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorLog -Scope "CONTAINER-STOP" `
                -Message "Force stop failed: $forceOutput"
            return 1
        }

        # Verify forced stop completed successfully
        # Wait briefly for container to fully terminate
        Start-Sleep -Seconds 2

        if (Test-ContainerRunning -ContainerName `
            "terminusdb-service") {
            Write-ErrorLog -Scope "CONTAINER-STOP" `
                -Message "Failed to stop container"
            return 1
        }

        Write-InfoLog -Scope "CONTAINER-STOP" `
            -Message "Container stopped (forced)"

        return 0
    }
    catch {
        # Handle unexpected errors during execution
        Write-ErrorLog -Scope "CONTAINER-STOP" `
            -Message "Error stopping container: $($_.Exception.Message)"
        return 1
    }
    finally {
        # Always return to original directory
        Pop-Location
    }
}

#endregion

#region Main Script Execution

Initialize-ScriptEnvironment
Assert-WindowsPlatform
Assert-PowerShellVersionStrict

try {
    Write-InfoLog -Scope "STOP-SCRIPT" `
        -Message "Stopping TerminusDB container"

    # Resolve repository root and Docker Compose file path
    $projectRoot = Get-RepositoryRoot

    $composePath = [System.IO.Path]::GetFullPath((Join-Path $projectRoot `
        "containers/terminusdb/terminusdb.docker-compose.yml"))

    # Validate Docker Compose file exists before proceeding
    Write-InfoLog -Scope "STOP-SCRIPT" `
        -Message "Validating Docker Compose file"

    if (-not (Test-DockerComposeFile -Path $composePath)) {
        Write-ErrorLog -Scope "STOP-SCRIPT" `
            -Message "Docker Compose file not found: $composePath"

        exit 1
    }

    # Verify Docker is available and daemon is running
    Write-InfoLog -Scope "STOP-SCRIPT" `
        -Message "Verifying Docker availability"

    if (-not (Test-DockerAvailable)) {
        Write-ErrorLog -Scope "STOP-SCRIPT" `
            -Message "Docker not available or daemon not running"

        exit 1
    }

    # Check if container is running
    # If not running, exit successfully without attempting stop
    Write-InfoLog -Scope "STOP-SCRIPT" `
        -Message "Checking container state"

    if (-not (Test-ContainerRunning -ContainerName "terminusdb-service")) {
        Write-InfoLog -Scope "STOP-SCRIPT" -Message "Container not running"

        exit 0
    }

    # Stop the container with graceful timeout and force stop fallback
    $stopResult = Stop-ContainerGracefully -ComposePath $composePath
    if ($stopResult -ne 0) {
        exit 1
    }

    Write-InfoLog -Scope "STOP-SCRIPT" `
        -Message "TerminusDB container stopped successfully"

    exit 0
}
catch {
    # Handle unexpected errors during script execution
    Write-ErrorLog -Scope "STOP-SCRIPT" `
        -Message "Unexpected error: $($_.Exception.Message)"

    Write-DebugLog -Scope "START-SCRIPT" `
        -Message "Stack Trace: $($_.ScriptStackTrace)"

    exit 1
}

#endregion
