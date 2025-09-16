#!/bin/bash

# Greenplum SNE Container Runner
# Manages running different Greenplum SNE container variants
#
# Usage: ./run-gpsne.sh [--base|--pxf|--full] [--stop|--status|--logs]

set -e

# Configuration
BASE_PORT=15432
PXF_PORT=5888
DEFAULT_VARIANT="full"

# Container names and images
get_container_name() {
    case $1 in
        base) echo "greenplum-sne-base" ;;  # This is both the container name AND the image name after installation
        pxf) echo "greenplum-sne-pxf" ;;
        full) echo "greenplum-sne-full" ;;
        *) echo "" ;;
    esac
}

# List of valid variants
VALID_VARIANTS="base pxf full"

# Parse command line arguments
COMMAND="start"
VARIANT=""

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
        --stop)
            COMMAND="stop"
            shift
            ;;
        --status)
            COMMAND="status"
            shift
            ;;
        --logs)
            COMMAND="logs"
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
    if [ "$COMMAND" == "start" ]; then
        VARIANT="$DEFAULT_VARIANT"
    fi
fi

# Function to show help
show_help() {
    echo "Greenplum SNE Container Runner"
    echo ""
    echo "Usage: ./run-gpsne.sh [OPTIONS]"
    echo ""
    echo "Container Options (for start command):"
    echo "  --base    Run the base Greenplum container"
    echo "  --pxf     Run Greenplum with PXF extension"
    echo "  --full    Run Greenplum with PXF and MADlib (default)"
    echo ""
    echo "Commands:"
    echo "  --stop    Stop running container(s)"
    echo "  --status  Show status of container(s)"
    echo "  --logs    Show logs from container(s)"
    echo "  --help    Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./run-gpsne.sh                  # Start full container (default)"
    echo "  ./run-gpsne.sh --base           # Start base container"
    echo "  ./run-gpsne.sh --pxf            # Start PXF container"
    echo "  ./run-gpsne.sh --full           # Start full container"
    echo "  ./run-gpsne.sh --stop           # Stop all GPSNE containers"
    echo "  ./run-gpsne.sh --stop --pxf     # Stop PXF container only"
    echo "  ./run-gpsne.sh --status         # Show all container statuses"
    echo "  ./run-gpsne.sh --logs --full    # Show logs for full container"
}

# Function to check if container exists
container_exists() {
    local name=$1
    docker ps -a --format "table {{.Names}}" | grep -q "^${name}$"
}

# Function to check if container is running
container_running() {
    local name=$1
    docker ps --format "table {{.Names}}" | grep -q "^${name}$"
}

# Function to stop container
stop_container() {
    local variant=$1
    local container_name=$(get_container_name "$variant")

    if [ -z "$container_name" ]; then
        return
    fi

    if container_exists "$container_name"; then
        if container_running "$container_name"; then
            echo "Stopping $container_name..."
            docker stop "$container_name"
            echo "✅ Stopped $container_name"
        else
            echo "Container $container_name is not running"
        fi

        echo "Removing container $container_name..."
        docker rm "$container_name" 2>/dev/null || true
        echo "✅ Removed $container_name"
    else
        echo "Container $container_name does not exist"
    fi
}

# Function to show container status
show_status() {
    local variant=$1

    if [ -n "$variant" ]; then
        # Show specific container status
        local container_name=$(get_container_name "$variant")
        if container_exists "$container_name"; then
            echo "Container: $container_name"
            docker ps -a --filter "name=^${container_name}$" --format "table {{.Status}}\t{{.Ports}}"
        else
            echo "Container $container_name does not exist"
        fi
    else
        # Show all GPSNE container statuses
        echo "=== Greenplum SNE Container Status ==="
        echo ""
        for variant in $VALID_VARIANTS; do
            local container_name=$(get_container_name "$variant")
            if container_exists "$container_name"; then
                echo "📦 $container_name ($variant):"
                if container_running "$container_name"; then
                    echo "   Status: Running ✅"
                    docker port "$container_name" 2>/dev/null | sed 's/^/   /'
                else
                    echo "   Status: Stopped ⏹️"
                fi
            else
                echo "📦 $container_name ($variant): Not created"
            fi
            echo ""
        done
    fi
}

# Function to show container logs
show_logs() {
    local variant=$1

    if [ -n "$variant" ]; then
        local container_name=$(get_container_name "$variant")
        if container_exists "$container_name"; then
            echo "=== Logs for $container_name ==="
            docker logs "$container_name" --tail 50
        else
            echo "Container $container_name does not exist"
        fi
    else
        # Show logs for all running GPSNE containers
        for variant in $VALID_VARIANTS; do
            local container_name=$(get_container_name "$variant")
            if container_running "$container_name"; then
                echo "=== Logs for $container_name ==="
                docker logs "$container_name" --tail 20
                echo ""
            fi
        done
    fi
}

# Function to start container
start_container() {
    local variant=$1
    local container_name=$(get_container_name "$variant")
    local image_name="${container_name}:latest"

    echo "=== Starting Greenplum SNE Container ==="
    echo "Variant: $variant"
    echo "Container: $container_name"
    echo "Image: $image_name"
    echo ""

    # Check if image exists
    if ! docker image inspect "$image_name" >/dev/null 2>&1; then
        echo "❌ Error: Image '$image_name' not found"
        echo ""
        echo "Please build the image first:"
        case $variant in
            base)
                echo "  ./build-gpsne.sh --base"
                ;;
            pxf)
                echo "  ./build-gpsne.sh --pxf"
                ;;
            full)
                echo "  ./build-gpsne.sh --full"
                ;;
        esac
        exit 1
    fi

    # Check if container already exists
    if container_exists "$container_name"; then
        if container_running "$container_name"; then
            echo "⚠️  Container $container_name is already running"
            echo ""
            echo "To restart, first stop it:"
            echo "  ./run-gpsne.sh --stop --$variant"
            exit 1
        else
            echo "Removing existing stopped container..."
            docker rm "$container_name"
        fi
    fi

    # Check for port conflicts
    if lsof -Pi :$BASE_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "⚠️  Warning: Port $BASE_PORT is already in use"
        echo "Another service or container may be using this port"
        echo ""
    fi

    if [ "$variant" == "pxf" ] && lsof -Pi :$PXF_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "⚠️  Warning: Port $PXF_PORT is already in use"
        echo "Another service or container may be using this port"
        echo ""
    fi

    # Start the container based on variant
    echo "Starting container..."
    case $variant in
        base)
            docker run -d \
                -p ${BASE_PORT}:5432 \
                --hostname greenplum-sne \
                --name "$container_name" \
                "$image_name"
            ;;
        pxf)
            docker run -d \
                -p ${BASE_PORT}:5432 \
                -p ${PXF_PORT}:5888 \
                --hostname greenplum-sne \
                --name "$container_name" \
                "$image_name"
            ;;
        full)
            docker run -d \
                -p ${BASE_PORT}:5432 \
                --hostname greenplum-sne \
                --name "$container_name" \
                "$image_name"
            ;;
    esac

    echo "✅ Container started successfully!"
    echo ""

    # Wait for database to be ready
    echo "Waiting for database to be ready..."
    sleep 5

    # Show connection information
    echo "=== Connection Information ==="
    echo "Host: localhost"
    echo "Port: $BASE_PORT"
    echo "User: gpadmin"
    echo "Password: VMware1!"
    echo "Database: postgres"
    echo ""

    case $variant in
        pxf)
            echo "PXF REST API: http://localhost:$PXF_PORT"
            echo ""
            ;;
        full)
            echo "Extensions available:"
            echo "  - PXF (Platform Extension Framework)"
            echo "  - MADlib (Machine Learning)"
            echo "  - pgvector (Vector Similarity Search)"
            echo ""
            ;;
    esac

    echo "To connect:"
    echo "  psql -h localhost -p $BASE_PORT -U gpadmin -d postgres"
    echo ""
    echo "To view logs:"
    echo "  ./run-gpsne.sh --logs --$variant"
    echo ""
    echo "To stop:"
    echo "  ./run-gpsne.sh --stop --$variant"
}

# Main execution
case $COMMAND in
    help)
        show_help
        ;;
    stop)
        if [ -n "$VARIANT" ]; then
            stop_container "$VARIANT"
        else
            # Stop all GPSNE containers
            echo "Stopping all Greenplum SNE containers..."
            for variant in $VALID_VARIANTS; do
                stop_container "$variant"
            done
        fi
        ;;
    status)
        show_status "$VARIANT"
        ;;
    logs)
        show_logs "$VARIANT"
        ;;
    start)
        start_container "$VARIANT"
        ;;
esac