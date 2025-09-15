#!/bin/bash

# Full Extensions Builder for Greenplum SNE
# Builds container with both PXF and MADlib extensions

set -e

# Configuration
BASE_IMAGE="greenplum-sne-base:latest"
PXF_IMAGE_NAME="greenplum-sne-pxf"
FULL_IMAGE_NAME="greenplum-sne-full"
VERSION="7.5.4-pxf7.0.0-madlib2.2.0"

echo "=== Greenplum SNE Full Extensions Builder ==="
echo "Building: ${FULL_IMAGE_NAME}:${VERSION}"
echo "Base Image: ${BASE_IMAGE}"
echo "Timestamp: $(date)"
echo ""

# Step 1: Check for base image
echo "Checking for base image..."
if ! docker image inspect "${BASE_IMAGE}" >/dev/null 2>&1; then
    echo "❌ Error: Base image '${BASE_IMAGE}' not found"
    echo "   Please build the base image first:"
    echo "   ./build-container.sh"
    exit 1
fi
echo "✅ Found base image: ${BASE_IMAGE}"

# Step 2: Check for required files
echo "Checking for required files..."

# Check for PXF RPM
if ! ls files/pxf-gp7-*.rpm 1> /dev/null 2>&1; then
    echo "❌ Error: PXF RPM file not found in files/ directory"
    echo "   Expected: files/pxf-gp7-*.rpm"
    exit 1
fi
echo "✅ Found PXF RPM file"

# Check for MADlib archive
if ! ls files/madlib-*.tar.gz 1> /dev/null 2>&1; then
    echo "❌ Error: MADlib archive not found in files/ directory"
    echo "   Expected: files/madlib-*.tar.gz"
    exit 1
fi
echo "✅ Found MADlib archive"

# Step 3: Build PXF container first (if not exists)
echo ""
echo "Step 1: Building PXF extension..."
if ! docker image inspect "${PXF_IMAGE_NAME}:latest" >/dev/null 2>&1; then
    echo "Building PXF container..."
    ./build-pxf-extension.sh
else
    echo "✅ PXF container already exists: ${PXF_IMAGE_NAME}:latest"
fi

# Step 4: Build full container with MADlib on top of PXF
echo ""
echo "Step 2: Building MADlib extension on top of PXF..."
docker build \
    --platform linux/amd64 \
    -f extensions/madlib/Dockerfile \
    -t "${FULL_IMAGE_NAME}:${VERSION}" \
    -t "${FULL_IMAGE_NAME}:latest" \
    .

echo ""
echo "✅ Full extensions build completed successfully!"
echo ""
echo "Images created:"
echo "  Full extension: ${FULL_IMAGE_NAME}:${VERSION}"
echo "  Also tagged as: ${FULL_IMAGE_NAME}:latest"
echo ""
echo "To run the fully-featured container:"
echo "  docker run -d -p 15432:5432 --hostname greenplum-sne --name greenplum-sne-full ${FULL_IMAGE_NAME}:latest"
echo ""
echo "To connect:"
echo "  psql -h localhost -p 15432 -U gpadmin -d postgres"
echo "  Password: VMware1!"
echo ""
echo "Features Available:"
echo "  ✅ Greenplum Database 7.5.4"
echo "  ✅ PXF 7.0.0 - Platform Extension Framework"
echo "  ✅ MADlib 2.2.0 - Machine Learning Library"
echo ""
echo "Extensions:"
echo "  - PXF: External table access (S3, HDFS, JDBC, etc.)"
echo "  - MADlib: In-database machine learning and statistics"