#!/bin/bash

# Greenplum SNE Full Stack Builder
# Builds base, PXF, and full analytics images in one shot

set -e

# Pretty banner
echo "=== Greenplum SNE Full Stack Builder ==="
echo "Timestamp: $(date)"
echo ""

echo "Step 1/3: Building base Greenplum image (greenplum-sne-base)"
./build-container.sh

echo ""
echo "Step 2/3: Building PXF extension image (greenplum-sne-pxf)"
./build-pxf-extension.sh

echo ""
echo "Step 3/3: Building full analytics image (greenplum-sne-full)"
./build-full-extensions.sh

echo ""
echo "✅ All builds completed successfully!"
echo "Available images:"
echo "  - greenplum-sne-base:7.5.4 (and latest)"
echo "  - greenplum-sne-pxf:latest"
echo "  - greenplum-sne-full:latest"
