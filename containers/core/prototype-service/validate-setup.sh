#!/bin/bash

# Validate Docker Compose Setup
# Checks if all required files and directories exist

echo "🔍 Validating Docker Compose Setup..."

errors=0

# Check required files
required_files=(
    "docker-compose.yml"
    "dockerfiles/Dockerfile.storybook"
    "dockerfiles/Dockerfile.images-file-service"
    "dockerfiles/Dockerfile.products-data-service"
    "dockerfiles/Dockerfile.products-component-service"
    "dockerfiles/Dockerfile.prototype-service"
    "../../../services/core/images-file-service/nginx/default.conf"
    "../../../services/core/prototype-service/nginx/default.conf"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Missing file: $file"
        errors=$((errors+1))
    else
        echo "✅ Found: $file"
    fi
done

# Check required directories
required_dirs=(
    "../../../prototype/web/core"
    "../../../services/core/images-file-service"
    "../../../services/core/products-data-service/fiber-go"
    "../../../services/core/products-component-service/nextjs"
    "../../../services/core/prototype-service"
)

for dir in "${required_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "❌ Missing directory: $dir"
        errors=$((errors+1))
    else
        echo "✅ Found: $dir"
    fi
done

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed or not in PATH"
    errors=$((errors+1))
else
    echo "✅ Docker is available"
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed or not in PATH"
    errors=$((errors+1))
else
    echo "✅ Docker Compose is available"
fi

echo ""
if [ $errors -eq 0 ]; then
    echo "🎉 Setup validation passed! Ready to start services."
    exit 0
else
    echo "❌ Setup validation failed with $errors errors."
    exit 1
fi
