#!/bin/bash

# Stop All Core Services - Docker Compose Version
# This script replicates the "Stop All Windows Core Services" task from tasks.json

set -e

echo "🛑 Stopping All Core Services..."

# Change to the directory containing docker-compose.yml
cd "$(dirname "$0")"

# Stop all services
echo "📦 Stopping services..."
docker-compose down

echo "✅ All Core Services Stopped!"
