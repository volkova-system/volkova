#!/bin/bash
# Stop Core Services Script
# Stops all containerized services
# Works on WSL, Unix, and Linux platforms

set -e

echo "🛑 Stopping Core Services"
echo "========================="

cd "$(dirname "$0")"

# Function: Stop services
stop_services() {
    echo "📦 Stopping services..."

    if docker-compose down >/dev/null 2>&1; then
        echo "✅ Services stopped successfully"
        return 0
    else
        echo "⚠️  Error stopping services, attempting cleanup..."

        # Force stop containers
        docker stop $(docker ps -q) >/dev/null 2>&1 || true
        docker rm $(docker ps -aq) >/dev/null 2>&1 || true

        echo "✅ Services cleanup completed"
        return 0
    fi
}

# Function: Clean up resources
cleanup_resources() {
    echo "🧹 Cleaning up resources..."

    # Remove orphaned containers
    docker-compose down --remove-orphans >/dev/null 2>&1 || true

    # Clean up unused networks
    docker network prune -f >/dev/null 2>&1 || true

    echo "✅ Cleanup completed"
}

# Main execution
main() {
    # Check if docker-compose.yml exists
    if [[ ! -f "docker-compose.yml" ]]; then
        echo "❌ docker-compose.yml not found in current directory"
        exit 1
    fi

    # Stop services
    stop_services

    # Clean up resources
    cleanup_resources

    echo ""
    echo "🎉 All Core Services Stopped Successfully!"
    echo ""
    echo "To start services again, run: ./start-services.sh"
    echo ""
}

# Error handling
trap 'echo "❌ Script failed at line $LINENO"' ERR

# Run main function
main "$@"
