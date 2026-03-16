#!/usr/bin/env pwsh
# Consolidated Core Services Startup Script
# Handles validation, diagnostics, fixes, and service startup automatically
# Requires PowerShell 7.5.5 or later

#Requires -Version 7.5.5

Write-Host "🚀 Starting Core Services" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green

Set-Location $PSScriptRoot

# Ensure we're in the correct directory and fix Docker context issues
Write-Host "🔧 Verifying working directory..." -ForegroundColor Yellow
$currentPath = Get-Location
Write-Host "Current directory: $currentPath" -ForegroundColor Cyan

# Set Docker Compose environment variables to fix path resolution
$env:COMPOSE_PROJECT_DIR = $currentPath.Path
$env:COMPOSE_FILE = "docker-compose.yml"
$env:DOCKER_BUILDKIT = "1"
$env:COMPOSE_DOCKER_CLI_BUILD = "1"

Write-Host "✅ Working directory verified" -ForegroundColor Green

# Function: Reset Docker Desktop to factory defaults
function Reset-DockerDesktopFactory {
    Write-Host "🏭 Performing Docker Desktop factory reset..." -ForegroundColor Yellow

    try {
        # Stop Docker Desktop completely
        Stop-DockerDesktop
        Start-Sleep -Seconds 5

        # Remove Docker Desktop data directories
        $dockerPaths = @(
            "$env:APPDATA\Docker",
            "$env:LOCALAPPDATA\Docker",
            "$env:PROGRAMDATA\Docker",
            "$env:USERPROFILE\.docker"
        )

        foreach ($path in $dockerPaths) {
            if (Test-Path $path) {
                Write-Host "   Removing $path..." -ForegroundColor Cyan
                Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        # Remove Docker services
        $dockerServices = Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*docker*" }
        foreach ($service in $dockerServices) {
            try {
                Stop-Service -Name $service.Name -Force -ErrorAction SilentlyContinue
                sc.exe delete $service.Name 2>$null | Out-Null
            } catch { }
        }

        # Clean registry entries
        try {
            Remove-Item -Path "HKCU:\Software\Docker Inc." -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "HKLM:\SOFTWARE\Docker Inc." -Recurse -Force -ErrorAction SilentlyContinue
        } catch { }

        Write-Host "✅ Factory reset completed" -ForegroundColor Green

        # Restart Docker Desktop
        Start-Sleep -Seconds 3
        return Start-DockerDesktop

    } catch {
        Write-Host "❌ Factory reset failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function: Check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function: Restart as Administrator if needed
function Restart-AsAdmin {
    if (-not (Test-Administrator)) {
        Write-Host "🔐 Restarting as Administrator..." -ForegroundColor Yellow
        Start-Process -FilePath "pwsh" -ArgumentList "-File", $PSCommandPath -Verb RunAs
        exit 0
    }
}

# Function: Stop Docker Desktop completely
function Stop-DockerDesktop {
    Write-Host "🛑 Stopping Docker Desktop..." -ForegroundColor Yellow

    $dockerProcesses = Get-Process | Where-Object {
        $_.ProcessName -like "*Docker*" -and $_.ProcessName -ne "dockerd"
    }

    foreach ($process in $dockerProcesses) {
        try {
            $process.CloseMainWindow() | Out-Null
            Start-Sleep -Seconds 1
            if (-not $process.HasExited) { $process.Kill() }
        } catch { }
    }

    $dockerServices = Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*docker*" }
    foreach ($service in $dockerServices) {
        if ($service.Status -eq "Running") {
            try { Stop-Service -Name $service.Name -Force -ErrorAction SilentlyContinue } catch { }
        }
    }
    Start-Sleep -Seconds 3
}
# Function: Start Docker Desktop
function Start-DockerDesktop {
    Write-Host "🚀 Starting Docker Desktop..." -ForegroundColor Yellow

    $dockerPaths = @(
        "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe",
        "${env:LOCALAPPDATA}\Programs\Docker\Docker\Docker Desktop.exe"
    )

    $dockerExe = $dockerPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if ($dockerExe) {
        Start-Process -FilePath $dockerExe -WindowStyle Hidden

        # Wait for Docker to initialize
        Write-Host "⏳ Waiting for Docker to initialize..." -ForegroundColor Yellow
        $timeout = 90
        while ($timeout -gt 0) {
            try {
                if (docker info 2>$null) {
                    Write-Host "✅ Docker is ready" -ForegroundColor Green
                    return $true
                }
            } catch { }
            Start-Sleep -Seconds 2
            $timeout -= 2
        }
        return $false
    }
    return $false
}

# Function: Clean Docker system
function Clean-DockerSystem {
    Write-Host "🧹 Cleaning Docker system..." -ForegroundColor Yellow
    try {
        docker system prune -f 2>$null | Out-Null
        docker context use default 2>$null | Out-Null
    } catch { }
}

# Function: Free required ports
function Free-RequiredPorts {
    Write-Host "🔓 Freeing required ports..." -ForegroundColor Yellow
    $ports = @(3690, 4979, 5173, 6039, 9630)

    foreach ($port in $ports) {
        try {
            $connections = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
            foreach ($conn in $connections) {
                $process = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
                if ($process) {
                    Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
                }
            }
        } catch { }
    }
}
# Function: Validate prerequisites
function Test-Prerequisites {
    Write-Host "🔍 Validating prerequisites..." -ForegroundColor Yellow

    # Check Docker installation
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Docker not found. Please install Docker Desktop." -ForegroundColor Red
        exit 1
    }

    # Check Docker Compose
    if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Docker Compose not found. Please install Docker Desktop." -ForegroundColor Red
        exit 1
    }

    # Check required files
    $requiredFiles = @(
        "docker-compose.yml",
        "dockerfiles\Dockerfile.storybook",
        "dockerfiles\Dockerfile.images-file-service",
        "dockerfiles\Dockerfile.products-data-service",
        "dockerfiles\Dockerfile.products-component-service",
        "dockerfiles\Dockerfile.prototype-service"
    )

    foreach ($file in $requiredFiles) {
        if (-not (Test-Path $file)) {
            Write-Host "❌ Missing required file: $file" -ForegroundColor Red
            Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow
            exit 1
        }
    }

    # Validate Docker Compose file paths
    Write-Host "🔍 Validating Docker Compose paths..." -ForegroundColor Yellow
    try {
        $composeContent = Get-Content "docker-compose.yml" -Raw

        # Check for incorrect path references
        if ($composeContent -match "services/containers") {
            Write-Host "❌ Found incorrect path reference in docker-compose.yml" -ForegroundColor Red
            Write-Host "The docker-compose.yml file contains 'services/containers' which should be 'containers/core/prototype-service'" -ForegroundColor Yellow
            exit 1
        }

        # Validate all context paths exist
        $contextPaths = @(
            "../../../prototype/web/core",
            "../../../services/core/images-file-service",
            "../../../services/core/products-data-service/fiber-go",
            "../../../services/core/products-component-service/nextjs",
            "../../../services/core/prototype-service"
        )

        foreach ($contextPath in $contextPaths) {
            if (-not (Test-Path $contextPath)) {
                Write-Host "❌ Missing context path: $contextPath" -ForegroundColor Red
                Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow
                exit 1
            }
        }

        Write-Host "✅ All paths validated" -ForegroundColor Green

        # Fix Docker Compose working directory issue
        Write-Host "🔧 Setting Docker Compose project directory..." -ForegroundColor Yellow
        $env:COMPOSE_PROJECT_DIR = $PWD.Path
        $env:COMPOSE_FILE = "docker-compose.yml"

    } catch {
        Write-Host "⚠️  Could not validate docker-compose.yml paths" -ForegroundColor Yellow
    }

    Write-Host "✅ Prerequisites validated" -ForegroundColor Green
}

# Function: Ensure Docker is working
function Ensure-DockerWorking {
    Write-Host "🔧 Ensuring Docker is working..." -ForegroundColor Yellow

    # Test if Docker is accessible
    if (docker info 2>$null) {
        Write-Host "✅ Docker is already working" -ForegroundColor Green
        return $true
    }

    # Check Docker Desktop context and engine mode
    Write-Host "🔍 Checking Docker Desktop configuration..." -ForegroundColor Yellow

    # Try to switch to Linux containers if in Windows mode
    try {
        $dockerInfo = docker version --format json 2>$null | ConvertFrom-Json
        if ($dockerInfo.Server.Os -eq "windows") {
            Write-Host "⚠️  Docker is in Windows container mode, switching to Linux..." -ForegroundColor Yellow

            # Find Docker Desktop executable
            $dockerPaths = @(
                "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe",
                "${env:LOCALAPPDATA}\Programs\Docker\Docker\Docker Desktop.exe"
            )

            $dockerExe = $dockerPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

            if ($dockerExe) {
                # Switch to Linux containers
                & $dockerExe -SwitchLinuxEngine
                Start-Sleep -Seconds 10

                # Wait for switch to complete
                $timeout = 60
                while ($timeout -gt 0) {
                    try {
                        $newInfo = docker version --format json 2>$null | ConvertFrom-Json
                        if ($newInfo.Server.Os -eq "linux") {
                            Write-Host "✅ Switched to Linux containers" -ForegroundColor Green
                            break
                        }
                    } catch { }
                    Start-Sleep -Seconds 2
                    $timeout -= 2
                }
            }
        }
    } catch { }

    # Test again after potential switch
    if (docker info 2>$null) {
        Write-Host "✅ Docker is now working" -ForegroundColor Green
        return $true
    }

    # Restart as admin if needed
    Restart-AsAdmin

    # Stop Docker completely
    Stop-DockerDesktop

    # Clean system
    Clean-DockerSystem

    # Free ports
    Free-RequiredPorts

    # Reset Docker Desktop settings
    Write-Host "🔄 Resetting Docker Desktop settings..." -ForegroundColor Yellow
    try {
        # Reset Docker context
        docker context use default 2>$null | Out-Null

        # Remove Docker Desktop data (forces clean restart)
        $dockerDataPath = "$env:APPDATA\Docker"
        if (Test-Path $dockerDataPath) {
            Remove-Item -Path "$dockerDataPath\settings.json" -Force -ErrorAction SilentlyContinue
        }

        # Automated Docker Desktop settings configuration
        Write-Host "⚙️  Configuring Docker Desktop settings..." -ForegroundColor Yellow

        # Create optimized Docker Desktop settings
        $dockerSettings = @{
            "useWindowsContainers" = $false
            "exposeDockerAPIOnTCP2375" = $false
            "useWSL2" = $true
            "wslEngineEnabled" = $true
            "useVirtualizationFramework" = $true
            "useVirtualizationFrameworkVirtioFS" = $true
            "useVirtualizationFrameworkRosetta" = $false
            "autoStart" = $true
            "openUIOnStartupDisabled" = $true
            "settingsVersion" = 1
        }

        # Write settings file
        $settingsPath = "$dockerDataPath\settings.json"
        New-Item -Path $dockerDataPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        $dockerSettings | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath -Force -ErrorAction SilentlyContinue

        Write-Host "✅ Docker Desktop settings configured" -ForegroundColor Green

    } catch {
        Write-Host "⚠️  Could not configure Docker Desktop settings automatically" -ForegroundColor Yellow
    }

    # Restart Docker services
    $dockerServices = Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*docker*" }
    foreach ($service in $dockerServices) {
        try { Restart-Service -Name $service.Name -Force -ErrorAction SilentlyContinue } catch { }
    }

    # Start Docker Desktop
    if (-not (Start-DockerDesktop)) {
        Write-Host "❌ Failed to start Docker Desktop" -ForegroundColor Red
        exit 1
    }

    return $true
}
# Function: Start services with retry
function Start-Services {
    Write-Host "📦 Starting services..." -ForegroundColor Yellow

    $maxRetries = 3
    $retryCount = 0

    while ($retryCount -lt $maxRetries) {
        try {
            # Check Docker daemon before attempting to start services
            if (-not (docker info 2>$null)) {
                Write-Host "⚠️  Docker daemon not accessible, attempting to fix..." -ForegroundColor Yellow
                Ensure-DockerWorking
            }

            $output = docker-compose up --build -d 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Services started successfully" -ForegroundColor Green
                return $true
            } else {
                $retryCount++

                # Check for specific Docker engine errors
                if ($output -match "docker_engine" -or $output -match "dockerDesktopLinuxEngine") {
                    Write-Host "⚠️  Docker engine connection issue detected..." -ForegroundColor Yellow

                    # Try to fix Docker engine issue
                    Write-Host "🔄 Attempting to fix Docker engine connection..." -ForegroundColor Yellow
                    Stop-DockerDesktop
                    Start-Sleep -Seconds 5
                    Start-DockerDesktop
                    Start-Sleep -Seconds 10
                }

                if ($retryCount -lt $maxRetries) {
                    Write-Host "⚠️  Attempt $retryCount failed, retrying..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 5
                    Clean-DockerSystem
                } else {
                    Write-Host "❌ Failed to start services after $maxRetries attempts" -ForegroundColor Red
                    Write-Host "Error details:" -ForegroundColor Yellow
                    Write-Host $output -ForegroundColor Red

                    # Provide specific troubleshooting for this error
                    Write-Host "`n🔧 Specific troubleshooting for this error:" -ForegroundColor Yellow
                    Write-Host "1. Try switching Docker Desktop engine mode:" -ForegroundColor Cyan
                    Write-Host "   - Open Docker Desktop Settings" -ForegroundColor White
                    Write-Host "   - Go to General → Use WSL 2 based engine" -ForegroundColor White
                    Write-Host "   - Toggle this setting and restart Docker Desktop" -ForegroundColor White
                    Write-Host "2. Reset Docker Desktop to factory defaults:" -ForegroundColor Cyan
                    Write-Host "   - Docker Desktop → Troubleshoot → Reset to factory defaults" -ForegroundColor White
                    Write-Host "3. Reinstall Docker Desktop if the issue persists" -ForegroundColor Cyan

                    return $false
                }
            }
        } catch {
            $retryCount++
            if ($retryCount -ge $maxRetries) {
                Write-Host "❌ Failed to start services: $($_.Exception.Message)" -ForegroundColor Red
                return $false
            }
        }
    }
    return $false
}

# Function: Wait for services to be healthy
function Wait-ForServices {
    Write-Host "⏳ Waiting for services to be ready..." -ForegroundColor Yellow

    $services = @(
        @{Name="Storybook"; Port=3690; Path="/"},
        @{Name="Images Service"; Port=5173; Path="/health"},
        @{Name="Products Data"; Port=4979; Path="/service/data/products/health"},
        @{Name="Products Component"; Port=6039; Path="/"},
        @{Name="Prototype Service"; Port=9630; Path="/"}
    )

    Start-Sleep -Seconds 15

    foreach ($service in $services) {
        $timeout = 60
        $ready = $false

        while ($timeout -gt 0 -and -not $ready) {
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:$($service.Port)$($service.Path)" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
                Write-Host "✅ $($service.Name) is ready" -ForegroundColor Green
                $ready = $true
            } catch {
                Start-Sleep -Seconds 2
                $timeout -= 2
            }
        }

        if (-not $ready) {
            Write-Host "⚠️  $($service.Name) may not be ready yet" -ForegroundColor Yellow
        }
    }
}
# Main execution
try {
    # Step 1: Validate prerequisites
    Test-Prerequisites

    # Step 2: Ensure Docker is working
    Ensure-DockerWorking

    # Step 3: Start services
    if (-not (Start-Services)) {
        Write-Host "❌ Failed to start services" -ForegroundColor Red
        exit 1
    }

    # Step 4: Wait for services to be ready
    Wait-ForServices

    # Success message
    Write-Host ""
    Write-Host "🎉 All Core Services Started Successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Service URLs:" -ForegroundColor Cyan
    Write-Host "   • Main Application:         http://localhost:9630" -ForegroundColor White
    Write-Host "   • Storybook:               http://localhost:3690" -ForegroundColor White
    Write-Host "   • Images Service:          http://localhost:5173" -ForegroundColor White
    Write-Host "   • Products Data API:       http://localhost:4979" -ForegroundColor White
    Write-Host "   • Products Component API:  http://localhost:6039" -ForegroundColor White
    Write-Host ""
    Write-Host "🔧 Management Commands:" -ForegroundColor Cyan
    Write-Host "   • View logs:    docker-compose logs -f" -ForegroundColor White
    Write-Host "   • Stop services: docker-compose down" -ForegroundColor White
    Write-Host "   • Restart:      .\start-services.ps1" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "❌ Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Keep window open only if run directly from Windows Explorer (not from terminal)
if ($Host.Name -eq "ConsoleHost" -and [Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
    # Only pause if launched by double-clicking (not from command line)
    $parentProcess = (Get-WmiObject Win32_Process -Filter "ProcessId=$PID").ParentProcessId
    $parent = Get-Process -Id $parentProcess -ErrorAction SilentlyContinue
    if ($parent -and $parent.ProcessName -eq "explorer") {
        Read-Host "Press Enter to exit"
    }
}
