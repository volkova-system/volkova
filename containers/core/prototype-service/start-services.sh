#!/bin/bash

# Start All Core Services - Docker Compose Version
# This script replicates the "Start All Windows Core Services" task from tasks.json

set -e

echo "🚀 Starting All Core Services with Docker Compose..."

# Change to the directory containing docker-compose.yml
cd "$(dirname "$0")"

# Build and start all services
echo "📦 Building and starting services..."
docker-compose up --build -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check service health
echo "🔍 Checking service health..."

services=("storybook:3690" "images-file-service:5173" "products-data-service:4979" "products-component-service:6039" "prototype-service:9630")

for service in "${services[@]}"; do
    name=$(echo $service | cut -d: -f1)
    port=$(echo $service | cut -d: -f2)

    echo "Checking $name on port $port..."

    # Wait up to 60 seconds for service to be ready
    timeout=60
    while [ $timeout -gt 0 ]; do
        if curl -f -s "http://localhost:$port" > /dev/null 2>&1 || \
           curl -f -s "http://localhost:$port/health" > /dev/null 2>&1; then
            echo "✅ $name is ready"
            break
        fi
        sleep 2
        timeout=$((timeout-2))
    done

    if [ $timeout -le 0 ]; then
        echo "⚠️  $name may not be ready yet (timeout reached)"
    fi
done

echo ""
echo "🎉 All Core Services Started!"
echo ""
echo "📋 Service URLs:"
echo "   • Storybook:                http://localhost:3690"
echo "   • Images File Service:      http://localhost:5173"
echo "   • Products Data Service:    http://localhost:4979"
echo "   • Products Component Service: http://localhost:6039"
echo "   • Prototype Service (Main): http://localhost:9630"
echo ""
echo "🔧 Management Commands:"
echo "   • View logs:    docker-compose logs -f"
echo "   • Stop services: docker-compose down"
echo "   • Restart:      docker-compose restart"
echo ""
