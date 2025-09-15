#!/bin/bash

# PXF Extension Builder for Greenplum SNE
# Builds PXF extension container using the greenplum-sne-base

set -e

# Configuration
BASE_IMAGE="greenplum-sne-base:latest"
PXF_IMAGE_NAME="greenplum-sne-pxf"
VERSION="7.5.4-pxf7.0.0"

echo "=== Greenplum SNE PXF Extension Builder ==="
echo "Building: ${PXF_IMAGE_NAME}:${VERSION}"
echo "Base Image: ${BASE_IMAGE}"
echo "Timestamp: $(date)"
echo ""

# Verify base image exists
echo "Checking for base image..."
if ! docker image inspect "${BASE_IMAGE}" >/dev/null 2>&1; then
    echo "❌ Error: Base image '${BASE_IMAGE}' not found"
    echo "   Please build the base image first:"
    echo "   ./build-container.sh"
    exit 1
fi

echo "✅ Found base image: ${BASE_IMAGE}"

# Verify PXF RPM exists
echo "Checking for PXF RPM..."
if ! ls files/pxf-gp7-*.rpm 1> /dev/null 2>&1; then
    echo "❌ Error: PXF RPM file not found in files/ directory"
    echo "   Expected: files/pxf-gp7-*.rpm"
    echo "   Please copy the PXF RPM from ../gpdb_installer/files/ or download from VMware Tanzu Network"
    exit 1
fi

echo "✅ Found PXF RPM file"

# Build PXF extension image
echo "Building PXF extension image..."
docker build \
    --platform linux/amd64 \
    -f extensions/pxf/Dockerfile \
    -t "${PXF_IMAGE_NAME}:${VERSION}" \
    -t "${PXF_IMAGE_NAME}:latest" \
    .

echo ""
echo "✅ PXF extension build completed successfully!"
echo ""
echo "Images created:"
echo "  PXF extension: ${PXF_IMAGE_NAME}:${VERSION}"
echo "  Also tagged as: ${PXF_IMAGE_NAME}:latest"
echo ""
echo "To run the PXF-enabled container:"
echo "  docker run -d -p 15432:5432 --hostname greenplum-sne --name greenplum-sne-pxf ${PXF_IMAGE_NAME}:${VERSION}"
echo ""
echo "To connect:"
echo "  psql -h localhost -p 15432 -U gpadmin -d postgres"
echo "  Password: VMware1!"
echo ""
echo "PXF Features Available:"
echo "  - External table access to file systems (HDFS, S3, etc.)"
echo "  - JDBC connectivity to external databases"  
echo "  - Integration with Hadoop ecosystem"