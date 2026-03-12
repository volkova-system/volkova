#!/bin/bash
# Consolidated Core Services Startup Script
# Handles validation, diagnostics, fixes, and service startup automatically
# Works on WSL, Unix, and Linux platforms

set -e

echo "🚀 Starting Core Services"
echo "========================="

cd "$(dirname "$0")"

# Function: Check if running as root/sudo
check_sudo() {
    if [[ $EUID -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Function: Restart with sudo if needed
restart_with_sudo() {
    if ! check_sudo; then
        echo "🔐 Restarting with sudo privileges..."
        exec sudo bash "$0" "$@"
    fi
}

# Function: Detect platform
detect_platform() {
    if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unix"
    fi
}

# Function: Stop Docker (platform-specific)
stop_docker() {
    echo "🛑 Stopping Docker..."
    local platform=$(detect_platform)

    case $platform in
        "wsl")
            # WSL - Docker Desktop runs on Windows host
            powershell.exe -Command "Stop-Process -Name 'Docker Desktop' -Force -ErrorAction SilentlyContinue" 2>/dev/null || true
            ;;
        "macos")
            # macOS - Docker Desktop
            pkill -f "Docker Desktop" 2>/dev/null || true
            launchctl stop com.docker.docker 2>/dev/null || true
            ;;
        "linux"|"unix")
            # Linux - Docker daemon
            systemctl stop docker 2>/dev/null || service docker stop 2>/dev/null || true
            pkill -f dockerd 2>/dev/null || true
            ;;
    esac

    sleep 3
}

# Function: Start Docker (platform-specific)
start_docker() {
    echo "🚀 Starting Docker..."
    local platform=$(detect_platform)

    case $platform in
        "wsl")
            # WSL - Start Docker Desktop on Windows host
            powershell.exe -Command "Start-Process -FilePath 'C:\\Program Files\\Docker\\Docker\\Docker Desktop.exe' -WindowStyle Hidden" 2>/dev/null || \
            powershell.exe -Command "Start-Process -FilePath '$env:LOCALAPPDATA\\Programs\\Docker\\Docker\\Docker Desktop.exe' -WindowStyle Hidden" 2>/dev/null || true
            ;;
        "macos")
            # macOS - Docker Desktop
            open -a "Docker Desktop" 2>/dev/null || \
            /Applications/Docker.app/Contents/MacOS/Docker --unattended 2>/dev/null &
            ;;
        "linux"|"unix")
            # Linux - Docker daemon
            systemctl start docker 2>/dev/null || service docker start 2>/dev/null || \
            dockerd --host=unix:///var/run/docker.sock --host=tcp://0.0.0.0:2376 2>/dev/null &
            ;;
    esac

    # Wait for Docker to initialize
    echo "⏳ Waiting for Docker to initialize..."
    local timeout=90
    while [ $timeout -gt 0 ]; do
        if docker info >/dev/null 2>&1; then
            echo "✅ Docker is ready"
            return 0
        fi
        sleep 2
        timeout=$((timeout-2))
    done

    echo "❌ Docker failed to start within timeout"
    return 1
}
# Function: Clean Docker system
clean_docker_system() {
    echo "🧹 Cleaning Docker system..."
    docker system prune -f >/dev/null 2>&1 || true
    docker context use default >/dev/null 2>&1 || true
}

# Function: Free required ports
free_required_ports() {
    echo "🔓 Freeing required ports..."
    local ports=(3690 4979 5173 6039 9630)

    for port in "${ports[@]}"; do
        # Find and kill processes using the port
        local pids=$(lsof -ti:$port 2>/dev/null || netstat -tlnp 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1 || true)
        if [[ -n "$pids" ]]; then
            echo "   Freeing port $port..."
            echo "$pids" | xargs -r kill -9 2>/dev/null || true
        fi
    done
}

# Function: Validate prerequisites
validate_prerequisites() {
    echo "🔍 Validating prerequisites..."

    # Check Docker installation
    if ! command -v docker >/dev/null 2>&1; then
        echo "❌ Docker not found. Please install Docker."
        exit 1
    fi

    # Check Docker Compose
    if ! command -v docker-compose >/dev/null 2>&1; then
        echo "❌ Docker Compose not found. Please install Docker Compose."
        exit 1
    fi

    # Check required files
    local required_files=(
        "docker-compose.yml"
        "dockerfiles/Dockerfile.storybook"
        "dockerfiles/Dockerfile.images-file-service"
        "dockerfiles/Dockerfile.products-data-service"
        "dockerfiles/Dockerfile.products-component-service"
        "dockerfiles/Dockerfile.prototype-service"
    )

    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            echo "❌ Missing required file: $file"
            exit 1
        fi
    done

    echo "✅ Prerequisites validated"
}
# Function: Ensure Docker is working
ensure_docker_working() {
    echo "🔧 Ensuring Docker is working..."

    # Test if Docker is accessible
    if docker info >/dev/null 2>&1; then
        echo "✅ Docker is already working"
        return 0
    fi

    # Request sudo if needed for Docker operations
    restart_with_sudo

    # Stop Docker completely
    stop_docker

    # Clean system
    clean_docker_system

    # Free ports
    free_required_ports

    # Start Docker
    if ! start_docker; then
        echo "❌ Failed to start Docker"
        exit 1
    fi

    return 0
}

# Function: Start services with retry
start_services() {
    echo "📦 Starting services..."

    local max_retries=3
    local retry_count=0

    while [ $retry_count -lt $max_retries ]; do
        if docker-compose up --build -d >/dev/null 2>&1; then
            echo "✅ Services started successfully"
            return 0
        else
            retry_count=$((retry_count+1))
            if [ $retry_count -lt $max_retries ]; then
                echo "⚠️  Attempt $retry_count failed, retrying..."
                sleep 5
                clean_docker_system
            else
                echo "❌ Failed to start services after $max_retries attempts"
                return 1
            fi
        fi
    done

    return 1
}
# Function: Wait for services to be healthy
wait_for_services() {
    echo "⏳ Waiting for services to be ready..."

    local services=(
        "Storybook:3690:/"
        "Images Service:5173:/health"
        "Products Data:4979:/service/data/products/health"
        "Products Component:6039:/"
        "Prototype Service:9630:/"
    )

    sleep 15

    for service_info in "${services[@]}"; do
        IFS=':' read -r name port path <<< "$service_info"
        local timeout=60
        local ready=false

        while [ $timeout -gt 0 ] && [ "$ready" = false ]; do
            if curl -f -s "http://localhost:$port$path" >/dev/null 2>&1; then
                echo "✅ $name is ready"
                ready=true
            else
                sleep 2
                timeout=$((timeout-2))
            fi
        done

        if [ "$ready" = false ]; then
            echo "⚠️  $name may not be ready yet"
        fi
    done
}

# Function: Install missing dependencies
install_dependencies() {
    local platform=$(detect_platform)

    # Install curl if missing
    if ! command -v curl >/dev/null 2>&1; then
        echo "📦 Installing curl..."
        case $platform in
            "wsl"|"linux")
                apt-get update >/dev/null 2>&1 && apt-get install -y curl >/dev/null 2>&1 || \
                yum install -y curl >/dev/null 2>&1 || \
                dnf install -y curl >/dev/null 2>&1 || true
                ;;
            "macos")
                brew install curl >/dev/null 2>&1 || true
                ;;
        esac
    fi

    # Install lsof if missing
    if ! command -v lsof >/dev/null 2>&1; then
        echo "📦 Installing lsof..."
        case $platform in
            "wsl"|"linux")
                apt-get update >/dev/null 2>&1 && apt-get install -y lsof >/dev/null 2>&1 || \
                yum install -y lsof >/dev/null 2>&1 || \
                dnf install -y lsof >/dev/null 2>&1 || true
                ;;
            "macos")
                # lsof is built-in on macOS
                ;;
        esac
    fi
}
# Main execution
main() {
    # Step 1: Install missing dependencies
    install_dependencies

    # Step 2: Validate prerequisites
    validate_prerequisites

    # Step 3: Ensure Docker is working
    ensure_docker_working

    # Step 4: Start services
    if ! start_services; then
        echo "❌ Failed to start services"
        exit 1
    fi

    # Step 5: Wait for services to be ready
    wait_for_services

    # Success message
    echo ""
    echo "🎉 All Core Services Started Successfully!"
    echo ""
    echo "📋 Service URLs:"
    echo "   • Main Application:         http://localhost:9630"
    echo "   • Storybook:               http://localhost:3690"
    echo "   • Images Service:          http://localhost:5173"
    echo "   • Products Data API:       http://localhost:4979"
    echo "   • Products Component API:  http://localhost:6039"
    echo ""
    echo "🔧 Management Commands:"
    echo "   • View logs:    docker-compose logs -f"
    echo "   • Stop services: docker-compose down"
    echo "   • Restart:      ./start-services.sh"
    echo ""
}

# Error handling
trap 'echo "❌ Script failed at line $LINENO"' ERR

# Run main function
main "$@"
