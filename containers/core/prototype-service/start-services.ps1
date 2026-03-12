#!/usr/bin/env pwsh
# Start All Core Services - Docker Compose Version
# This script replicates the "Start All Windows Core Services" task from tasks.json
# Requires PowerShell 7.5.4 or later

#Requires -Version 7.5.4

Write-Host "🚀 Starting All Core Services with Docker Compose..." -ForegroundColor Green

# Change to the directory containing docker-compose.yml
Set-Location $PSScriptRoot

# Build and start all services
Write-Host "📦 Building and starting services..." -ForegroundColor Yellow
docker-compose up --build -d

# Wait for services to be ready
Write-Host "⏳ Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Check service health
Write-Host "🔍 Checking service health..." -ForegroundColor Yellow

$services = @(
    @{Name="storybook"; Port=3690},
    @{Name="images-file-service"; Port=5173},
    @{Name="products-data-service"; Port=4979},
    @{Name="products-component-service"; Port=6039},
    @{Name="prototype-service"; Port=9630}
)

foreach ($service in $services) {
    Write-Host "Checking $($service.Name) on port $($service.Port)..." -ForegroundColor Cyan

    # Wait up to 60 seconds for service to be ready
    $timeout = 60
    $ready = $false

    while ($timeout -gt 0 -and -not $ready) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:$($service.Port)" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
            Write-Host "✅ $($service.Name) is ready" -ForegroundColor Green
            $ready = $true
        }
        catch {
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:$($service.Port)/health" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
                Write-Host "✅ $($service.Name) is ready" -ForegroundColor Green
                $ready = $true
            }
            catch {
                Start-Sleep -Seconds 2
                $timeout -= 2
            }
        }
    }

    if (-not $ready) {
        Write-Host "⚠️  $($service.Name) may not be ready yet (timeout reached)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "🎉 All Core Services Started!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Service URLs:" -ForegroundColor Cyan
Write-Host "   • Storybook:                http://localhost:3690"
Write-Host "   • Images File Service:      http://localhost:5173"
Write-Host "   • Products Data Service:    http://localhost:4979"
Write-Host "   • Products Component Service: http://localhost:6039"
Write-Host "   • Prototype Service (Main): http://localhost:9630"
Write-Host ""
Write-Host "🔧 Management Commands:" -ForegroundColor Cyan
Write-Host "   • View logs:    docker-compose logs -f"
Write-Host "   • Stop services: docker-compose down"
Write-Host "   • Restart:      docker-compose restart"
Write-Host ""

Read-Host "Press Enter to continue"
