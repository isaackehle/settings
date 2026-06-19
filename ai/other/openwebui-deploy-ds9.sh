#!/bin/bash

# OpenWebUI deployment script for ds9 (Mac mini M2 16GB)
# This script installs and configures OpenWebUI to work with local Ollama

set -euo pipefail

CONTAINER_NAME="openwebui"
PORT=8080
IMAGE="ghcr.io/open-webui/open-webui:main"

echo "=== OpenWebUI Deployment for ds9 ==="
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Installing via Colima..."
    brew install colima docker docker-compose
    colima start --cpu 2 --memory 4
else
    echo "✓ Docker found"
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        echo "Starting Docker daemon..."
        if command -v colima &> /dev/null; then
            colima start --cpu 2 --memory 4
        else
            echo "❌ Docker daemon not running. Please start Colima or Docker Desktop."
            exit 1
        fi
    fi
fi

# Check if container already exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "⚠ Container '${CONTAINER_NAME}' already exists"
    read -p "Remove and recreate? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker rm -f "${CONTAINER_NAME}"
    else
        echo "Starting existing container..."
        docker start "${CONTAINER_NAME}"
        echo ""
        echo "✓ OpenWebUI started at http://localhost:${PORT}"
        exit 0
    fi
fi

# Check if Ollama is running
if ! nc -z localhost 11434 2>/dev/null; then
    echo "⚠ Warning: Ollama not detected on port 11434"
    echo "  OpenWebUI will still start, but you'll need to configure Ollama connection"
    echo ""
fi

# Pull image
echo "Pulling OpenWebUI image..."
docker pull "${IMAGE}"

# Run container
echo "Starting OpenWebUI container..."
docker run -d \
    --name "${CONTAINER_NAME}" \
    --restart unless-stopped \
    -p "${PORT}:8080" \
    -v openwebui:/app/backend/data \
    --add-host=host.docker.internal:host-gateway \
    "${IMAGE}"

# Wait for container to be healthy
echo "Waiting for OpenWebUI to start..."
for i in {1..30}; do
    if docker ps --format '{{.Names}} {{.Status}}' | grep -q "${CONTAINER_NAME}.*healthy"; then
        break
    fi
    sleep 2
done

echo ""
echo "✓ OpenWebUI deployed successfully!"
echo ""
echo "Access URL: http://localhost:${PORT}"
echo ""
echo "Next steps:"
echo "  1. Open http://localhost:${PORT} in your browser"
echo "  2. Create an admin account (first user becomes admin)"
echo "  3. Go to Settings → Admin Settings → Connections"
echo "  4. Add Ollama API: http://host.docker.internal:11434"
echo "  5. Test the connection"
echo ""
echo "To manage OpenWebUI:"
echo "  Start:   docker start ${CONTAINER_NAME}"
echo "  Stop:    docker stop ${CONTAINER_NAME}"
echo "  Logs:    docker logs -f ${CONTAINER_NAME}"
echo "  Remove:  docker rm -f ${CONTAINER_NAME}"
echo ""
