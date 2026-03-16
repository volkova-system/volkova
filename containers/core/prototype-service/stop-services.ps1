#!/usr/bin/env pwsh
# Stop All Core Services - Docker Compose Version
# This script replicates the "Stop All Windows Core Services" task from tasks.json
# Requires PowerShell 7.5.5 or later

#Requires -Version 7.5.5

Write-Host "🛑 Stopping All Core Services..." -ForegroundColor Red

# Change to the directory containing docker-compose.yml
Set-Location $PSScriptRoot

# Stop all services
Write-Host "📦 Stopping services..." -ForegroundColor Yellow
docker-compose down

Write-Host "✅ All Core Services Stopped!" -ForegroundColor Green

Read-Host "Press Enter to continue"
