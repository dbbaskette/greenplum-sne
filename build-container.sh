#!/bin/bash

# Greenplum Single Node Container Builder
# Builds a clean Greenplum database container with only core database functionality

set -e

# Configuration
BASE_IMAGE_NAME="greenplum-base"
INSTALLED_IMAGE_NAME="greenplum-db"
VERSION="7.5.4"
BUILD_CONTAINER_NAME="greenplum-build-temp"

echo "=== Greenplum Single Node Container Builder ==="
echo "Building: ${INSTALLED_IMAGE_NAME}:${VERSION}"
echo "Timestamp: $(date)"
echo ""

# Verify required files exist
echo "Checking for required files..."
if ! ls files/greenplum-db-${VERSION}*.rpm 1> /dev/null 2>&1; then
    echo "❌ Error: Greenplum RPM file not found in files/ directory"
    echo "   Expected: files/greenplum-db-${VERSION}*.rpm"
    echo "   Please download the Greenplum RPM from VMware Tanzu Network"
    exit 1
fi

echo "✅ Found Greenplum RPM file"

# Clean up any existing build container
echo "Cleaning up any existing build container..."
docker stop "$BUILD_CONTAINER_NAME" 2>/dev/null || true
docker rm "$BUILD_CONTAINER_NAME" 2>/dev/null || true

# Step 1: Build the base container (without Greenplum installed)
echo "Step 1: Building base container image..."
docker build \
    --platform linux/amd64 \
    -f container/Dockerfile \
    -t "${BASE_IMAGE_NAME}:${VERSION}" \
    .

echo "✅ Base container built successfully"

# Step 2: Run container and install Greenplum
echo "Step 2: Running container to install Greenplum..."
docker run -d \
    --platform linux/amd64 \
    --hostname greenplum-sne \
    --name "$BUILD_CONTAINER_NAME" \
    "${BASE_IMAGE_NAME}:${VERSION}"

echo "Waiting for container to start..."
sleep 5

# Wait for installation to complete (check logs for completion)
echo "Waiting for Greenplum installation to complete..."
attempt=1
max_attempts=60  # 10 minutes max

while [ $attempt -le $max_attempts ]; do
    # Check if installation completed successfully
    if docker logs "$BUILD_CONTAINER_NAME" 2>&1 | grep -q "=== Greenplum Database Installation Completed ==="; then
        echo "✅ Greenplum installation completed!"
        break
    fi
    
    # Check for installation failure
    if docker logs "$BUILD_CONTAINER_NAME" 2>&1 | grep -q "ERROR:"; then
        echo "❌ Installation failed. Check logs:"
        docker logs "$BUILD_CONTAINER_NAME" | tail -20
        exit 1
    fi
    
    if [ $((attempt % 6)) -eq 0 ]; then
        minutes=$((attempt / 6))
        echo "Still installing... ${minutes} minute(s) elapsed"
    else
        echo -n "."
    fi
    
    sleep 10
    ((attempt++))
done

if [ $attempt -gt $max_attempts ]; then
    echo "❌ Installation timed out. Check logs:"
    docker logs "$BUILD_CONTAINER_NAME" | tail -20
    exit 1
fi

# Step 3: Stop container and commit as installed image
echo "Step 3: Stopping container and committing installed image..."
docker stop "$BUILD_CONTAINER_NAME"

docker commit "$BUILD_CONTAINER_NAME" "${INSTALLED_IMAGE_NAME}:${VERSION}"
docker tag "${INSTALLED_IMAGE_NAME}:${VERSION}" "${INSTALLED_IMAGE_NAME}:latest"

# Clean up build container
echo "Cleaning up build container..."
docker rm "$BUILD_CONTAINER_NAME"

echo ""
echo "✅ Build completed successfully!"
echo ""
echo "Images created:"
echo "  Base image: ${BASE_IMAGE_NAME}:${VERSION}"
echo "  Installed image: ${INSTALLED_IMAGE_NAME}:${VERSION}"
echo "  Also tagged as: ${INSTALLED_IMAGE_NAME}:latest"
echo ""
echo "To run the installed container:"
echo "  docker run -d -p 15432:5432 --hostname greenplum-sne --name greenplum-sne ${INSTALLED_IMAGE_NAME}:${VERSION}"
echo ""
echo "To connect:"
echo "  psql -h localhost -p 15432 -U gpadmin -d postgres"
echo "  Password: VMware1!"