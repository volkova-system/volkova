#!/usr/bin/env pwsh
# Validate Docker Compose Setup
# Checks if all required files and directories exist
# Requires PowerShell 7.5.4 or later

#Requires -Version 7.5.4

Write-Host "🔍 Validating Docker Compose Setup..." -ForegroundColor Cyan

$errors = 0

# Check required files
$requiredFiles = @(
    "docker-compose.yml",
    "dockerfiles\Dockerfile.storybook",
    "dockerfiles\Dockerfile.images-file-service",
    "dockerfiles\Dockerfile.products-data-service",
    "dockerfiles\Dockerfile.products-component-service",
    "dockerfiles\Dockerfile.prototype-service",
    "..\..\..\services\core\images-file-service\nginx\default.conf",
    "..\..\..\services\core\prototype-service\nginx\default.conf"
)

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "✅ Found: $file" -ForegroundColor Green
    } else {
        Write-Host "❌ Missing file: $file" -ForegroundColor Red
        $errors++
    }
}

# Check required directories
$requiredDirs = @(
    "..\..\..\prototype\web\core",
    "..\..\..\services\core\images-file-service",
    "..\..\..\services\core\products-data-service\fiber-go",
    "..\..\..\services\core\products-component-service\nextjs",
    "..\..\..\services\core\prototype-service"
)

foreach ($dir in $requiredDirs) {
    if (Test-Path $dir -PathType Container) {
        Write-Host "✅ Found: $dir" -ForegroundColor Green
    } else {
        Write-Host "❌ Missing directory: $dir" -ForegroundColor Red
        $errors++
    }
}

# Check Docker
try {
    $dockerVersion = docker --version 2>$null
    if ($dockerVersion) {
        Write-Host "✅ Docker is available: $dockerVersion" -ForegroundColor Green
    } else {
        Write-Host "❌ Docker is not installed or not in PATH" -ForegroundColor Red
        $errors++
    }
} catch {
    Write-Host "❌ Docker is not installed or not in PATH" -ForegroundColor Red
    $errors++
}

try {
    $dockerComposeVersion = docker-compose --version 2>$null
    if ($dockerComposeVersion) {
        Write-Host "✅ Docker Compose is available: $dockerComposeVersion" -ForegroundColor Green
    } else {
        Write-Host "❌ Docker Compose is not installed or not in PATH" -ForegroundColor Red
        $errors++
    }
} catch {
    Write-Host "❌ Docker Compose is not installed or not in PATH" -ForegroundColor Red
    $errors++
}

Write-Host ""
if ($errors -eq 0) {
    Write-Host "🎉 Setup validation passed! Ready to start services." -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ Setup validation failed with $errors errors." -ForegroundColor Red
    exit 1
}

Read-Host "Press Enter to continue"
