#!/bin/bash

# Greenplum SNE Container Builder
# Unified builder for all Greenplum SNE container variants
#
# Usage: ./build-gpsne.sh [--base|--pxf|--full] [OPTIONS]

set -e

# Configuration
BASE_IMAGE_NAME="greenplum-base"  # Initial build image
INSTALLED_IMAGE_NAME="greenplum-sne-base"  # Committed image with Greenplum installed
PXF_IMAGE_NAME="greenplum-sne-pxf"
FULL_IMAGE_NAME="greenplum-sne-full"
BASE_VERSION="7.5.4"
PXF_VERSION="7.5.4-pxf7.0.0"
FULL_VERSION="7.5.4-pxf7.0.0-madlib2.2.0"
BUILD_CONTAINER_NAME="greenplum-build-temp"
DEFAULT_VARIANT="base"

# Container image names
get_image_info() {
    case $1 in
        base)
            echo "${INSTALLED_IMAGE_NAME}:${BASE_VERSION}"
            ;;
        pxf)
            echo "${PXF_IMAGE_NAME}:${PXF_VERSION}"
            ;;
        full)
            echo "${FULL_IMAGE_NAME}:${FULL_VERSION}"
            ;;
        *)
            echo ""
            ;;
    esac
}

# List of valid variants
VALID_VARIANTS="base pxf full"

# Parse command line arguments
COMMAND="build"
VARIANT=""
KEEP_INTERMEDIATE=false
NO_CACHE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --base)
            VARIANT="base"
            shift
            ;;
        --pxf)
            VARIANT="pxf"
            shift
            ;;
        --full)
            VARIANT="full"
            shift
            ;;
        --all)
            VARIANT="all"
            shift
            ;;
        --clean)
            COMMAND="clean"
            shift
            ;;
        --status)
            COMMAND="status"
            shift
            ;;
        --keep-intermediate)
            KEEP_INTERMEDIATE=true
            shift
            ;;
        --no-cache)
            NO_CACHE=true
            shift
            ;;
        --help|-h)
            COMMAND="help"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Set default variant if not specified
if [ -z "$VARIANT" ]; then
    if [ "$COMMAND" == "build" ]; then
        VARIANT="$DEFAULT_VARIANT"
    fi
fi

# Function to show help
show_help() {
    echo "Greenplum SNE Container Builder"
    echo ""
    echo "Usage: ./build-gpsne.sh [OPTIONS]"
    echo ""
    echo "Build Options:"
    echo "  --base              Build the base Greenplum container (default)"
    echo "  --pxf               Build Greenplum with PXF extension"
    echo "  --full              Build Greenplum with PXF and MADlib"
    echo "  --all               Build all container variants"
    echo ""
    echo "Additional Options:"
    echo "  --keep-intermediate Keep intermediate images (for --full builds)"
    echo "  --no-cache          Build without using Docker cache"
    echo ""
    echo "Commands:"
    echo "  --clean             Remove all GPSNE images"
    echo "  --status            Show status of GPSNE images"
    echo "  --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./build-gpsne.sh                    # Build base container"
    echo "  ./build-gpsne.sh --pxf              # Build PXF container"
    echo "  ./build-gpsne.sh --full             # Build full container"
    echo "  ./build-gpsne.sh --all              # Build all variants"
    echo "  ./build-gpsne.sh --full --no-cache  # Rebuild full container from scratch"
    echo "  ./build-gpsne.sh --clean            # Remove all GPSNE images"
    echo "  ./build-gpsne.sh --status           # Show all image statuses"
}

# Function to check if image exists
image_exists() {
    local image=$1
    docker image inspect "$image" >/dev/null 2>&1
}

# Function to get image size
get_image_size() {
    local image=$1
    if image_exists "$image"; then
        docker images --format "{{.Size}}" "$image"
    else
        echo "N/A"
    fi
}

# Function to show image status
show_status() {
    echo "=== Greenplum SNE Image Status ==="
    echo ""

    for variant in $VALID_VARIANTS; do
        local image_info=$(get_image_info "$variant")
        local image_name="${image_info%:*}"
        local image_tag="${image_info#*:}"

        echo "📦 $variant variant:"
        echo "   Image: $image_info"

        if image_exists "$image_info"; then
            echo "   Status: Built ✅"
            echo "   Size: $(get_image_size "$image_info")"

            # Check for latest tag too
            if image_exists "${image_name}:latest"; then
                echo "   Latest: Tagged ✅"
            fi
        else
            echo "   Status: Not built ❌"
        fi
        echo ""
    done

    # Show any dangling images
    local dangling_count=$(docker images -f "dangling=true" --format "{{.ID}}" | wc -l | tr -d ' ')
    if [ "$dangling_count" -gt 0 ]; then
        echo "⚠️  Dangling images: $dangling_count"
        echo "   Run 'docker image prune' to clean up"
    fi
}

# Function to clean images
clean_images() {
    echo "=== Cleaning Greenplum SNE Images ==="
    echo ""

    if [ -n "$1" ]; then
        # Clean specific variant
        local image_info=$(get_image_info "$1")
        local image_name="${image_info%:*}"

        echo "Removing $1 variant images..."
        docker rmi "${image_info}" 2>/dev/null || echo "  Image ${image_info} not found"
        docker rmi "${image_name}:latest" 2>/dev/null || echo "  Image ${image_name}:latest not found"
    else
        # Clean all GPSNE images
        echo "Removing all Greenplum SNE images..."
        for variant in $VALID_VARIANTS; do
            local image_info=$(get_image_info "$variant")
            local image_name="${image_info%:*}"

            echo "Removing $variant images..."
            docker rmi "${image_info}" 2>/dev/null || true
            docker rmi "${image_name}:latest" 2>/dev/null || true
        done

        echo ""
        echo "Removing dangling images..."
        docker image prune -f
    fi

    echo ""
    echo "✅ Cleanup completed"
}

# Function to build base image
build_base() {
    echo "=== Building Base Greenplum Container ==="
    echo "Image: ${INSTALLED_IMAGE_NAME}:${BASE_VERSION}"
    echo "Timestamp: $(date)"
    echo ""

    # Check for required files
    echo "Checking for required files..."
    if [ ! -f "container/Dockerfile" ]; then
        echo "❌ Error: container/Dockerfile not found"
        exit 1
    fi

    if ! ls files/greenplum-db-*.rpm 1> /dev/null 2>&1; then
        echo "❌ Error: Greenplum RPM file not found in files/ directory"
        echo "   Expected: files/greenplum-db-*.rpm"
        exit 1
    fi
    echo "✅ Found required files"
    echo ""

    # Clean up any existing build container
    echo "Cleaning up any existing build container..."
    docker stop "$BUILD_CONTAINER_NAME" 2>/dev/null || true
    docker rm "$BUILD_CONTAINER_NAME" 2>/dev/null || true

    # Step 1: Build the base container (without Greenplum installed)
    echo "Step 1: Building base container image..."
    local cache_flag=""
    if [ "$NO_CACHE" = true ]; then
        cache_flag="--no-cache"
    fi

    docker build \
        --platform linux/amd64 \
        $cache_flag \
        -f container/Dockerfile \
        -t "${BASE_IMAGE_NAME}:${BASE_VERSION}" \
        .

    echo "✅ Base container built successfully"

    # Step 2: Run container and install Greenplum
    echo "Step 2: Running container to install Greenplum..."
    docker run -d \
        --platform linux/amd64 \
        --hostname greenplum-sne \
        --name "$BUILD_CONTAINER_NAME" \
        "${BASE_IMAGE_NAME}:${BASE_VERSION}"

    echo "Waiting for container to start..."
    sleep 5

    # Wait for installation to complete
    echo "Waiting for Greenplum installation to complete..."
    local attempt=1
    local max_attempts=60  # 10 minutes max

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

    docker commit "$BUILD_CONTAINER_NAME" "${INSTALLED_IMAGE_NAME}:${BASE_VERSION}"
    docker tag "${INSTALLED_IMAGE_NAME}:${BASE_VERSION}" "${INSTALLED_IMAGE_NAME}:latest"

    # Clean up build container
    echo "Cleaning up build container..."
    docker rm "$BUILD_CONTAINER_NAME"

    echo ""
    echo "✅ Base container built and installed successfully!"
}

# Function to build PXF image
build_pxf() {
    echo "=== Building PXF Extension Container ==="
    echo "Image: ${PXF_IMAGE_NAME}:${PXF_VERSION}"
    echo "Timestamp: $(date)"
    echo ""

    # Check for base image
    echo "Checking dependencies..."
    if ! image_exists "${INSTALLED_IMAGE_NAME}:latest"; then
        echo "Base image not found. Building base first..."
        build_base
    fi

    # Check for required files
    if ! ls files/pxf-gp7-*.rpm 1> /dev/null 2>&1; then
        echo "❌ Error: PXF RPM file not found in files/ directory"
        echo "   Expected: files/pxf-gp7-*.rpm"
        exit 1
    fi
    echo "✅ Found PXF RPM file"
    echo ""

    # Build PXF container
    local cache_flag=""
    if [ "$NO_CACHE" = true ]; then
        cache_flag="--no-cache"
    fi

    echo "Building PXF container..."
    docker build \
        --platform linux/amd64 \
        $cache_flag \
        -f extensions/pxf/Dockerfile \
        -t "${PXF_IMAGE_NAME}:${PXF_VERSION}" \
        -t "${PXF_IMAGE_NAME}:latest" \
        .

    echo ""
    echo "✅ PXF container built successfully!"
}

# Function to build full image
build_full() {
    echo "=== Building Full Extensions Container ==="
    echo "Image: ${FULL_IMAGE_NAME}:${FULL_VERSION}"
    echo "Timestamp: $(date)"
    echo ""

    # Check for PXF image (build if needed)
    echo "Checking dependencies..."
    if ! image_exists "${PXF_IMAGE_NAME}:latest"; then
        echo "PXF image not found. Building PXF first..."
        build_pxf
    fi

    # Check for required files
    if ! ls files/madlib-*.tar.gz 1> /dev/null 2>&1; then
        echo "❌ Error: MADlib archive not found in files/ directory"
        echo "   Expected: files/madlib-*.tar.gz"
        exit 1
    fi
    echo "✅ Found MADlib archive"
    echo ""

    # Build full container
    local cache_flag=""
    if [ "$NO_CACHE" = true ]; then
        cache_flag="--no-cache"
    fi

    echo "Building full container with MADlib..."
    docker build \
        --platform linux/amd64 \
        $cache_flag \
        -f extensions/madlib/Dockerfile \
        -t "${FULL_IMAGE_NAME}:${FULL_VERSION}" \
        -t "${FULL_IMAGE_NAME}:latest" \
        .

    echo ""
    echo "✅ Full container built successfully!"

    # Clean up intermediate images if requested
    if [ "$KEEP_INTERMEDIATE" = false ]; then
        echo ""
        echo "Cleaning up intermediate images..."
        docker rmi "${PXF_IMAGE_NAME}:latest" 2>/dev/null || echo "  PXF image already removed or in use"
        docker image prune -f 2>/dev/null || echo "  No dangling images to remove"
    else
        echo ""
        echo "Keeping intermediate images (--keep-intermediate flag used)"
    fi
}

# Function to build all variants
build_all() {
    echo "=== Building All Greenplum SNE Variants ==="
    echo "Timestamp: $(date)"
    echo ""

    # Build in order: base -> pxf -> full
    echo "Step 1/3: Building base container..."
    build_base

    echo ""
    echo "Step 2/3: Building PXF container..."
    build_pxf

    echo ""
    echo "Step 3/3: Building full container..."
    build_full

    echo ""
    echo "=== Build Summary ==="
    show_status
}

# Function to show build summary
show_summary() {
    local variant=$1
    local image_info=$(get_image_info "$variant")

    echo ""
    echo "=== Build Complete ==="
    echo "Image: $image_info"
    echo "Also tagged as: ${image_info%:*}:latest"
    echo "Size: $(get_image_size "$image_info")"
    echo ""

    case $variant in
        base)
            echo "Features:"
            echo "  ✅ Greenplum Database ${BASE_VERSION}"
            echo ""
            echo "To run:"
            echo "  ./run-gpsne.sh --base"
            ;;
        pxf)
            echo "Features:"
            echo "  ✅ Greenplum Database ${BASE_VERSION}"
            echo "  ✅ PXF 7.0.0 - Platform Extension Framework"
            echo ""
            echo "To run:"
            echo "  ./run-gpsne.sh --pxf"
            ;;
        full)
            echo "Features:"
            echo "  ✅ Greenplum Database ${BASE_VERSION}"
            echo "  ✅ PXF 7.0.0 - Platform Extension Framework"
            echo "  ✅ MADlib 2.2.0 - Machine Learning Library"
            echo "  ✅ pgvector 0.7.0 - Vector Similarity Search"
            echo "  ✅ PL/Python3U with NumPy, scikit-learn, pandas"
            echo ""
            echo "To run:"
            echo "  ./run-gpsne.sh --full"
            ;;
    esac

    echo ""
    echo "Connection info:"
    echo "  Host: localhost"
    echo "  Port: 15432"
    echo "  User: gpadmin"
    echo "  Password: VMware1!"
}

# Main execution
case $COMMAND in
    help)
        show_help
        ;;
    status)
        show_status
        ;;
    clean)
        clean_images "$VARIANT"
        ;;
    build)
        case $VARIANT in
            base)
                build_base
                show_summary "base"
                ;;
            pxf)
                build_pxf
                show_summary "pxf"
                ;;
            full)
                build_full
                show_summary "full"
                ;;
            all)
                build_all
                ;;
            *)
                echo "Error: Invalid variant '$VARIANT'"
                echo "Valid options: --base, --pxf, --full, --all"
                exit 1
                ;;
        esac
        ;;
esac