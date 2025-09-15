#!/bin/bash

# Greenplum Database Startup Script for Pre-installed Container
# This script assumes Greenplum is already installed and just starts the services

set -e

echo "=== Greenplum Pre-installed Container Startup ==="
echo "Timestamp: $(date)"

# Start SSH daemon
echo "Starting SSH daemon..."
/usr/sbin/sshd -D &
SSH_PID=$!

# Wait for SSH to be ready
sleep 3

# Set up signal handlers for graceful shutdown
shutdown_handler() {
    echo "Shutting down Greenplum..."
    sudo -u gpadmin bash -c "
        source /usr/local/greenplum-db/greenplum_path.sh 2>/dev/null || true
        export COORDINATOR_DATA_DIRECTORY=/home/gpdata/coordinator/gpseg-1
        if [ -f \$GPHOME/bin/gpstop ]; then
            \$GPHOME/bin/gpstop -a -M fast 2>/dev/null || true
        fi
    "
    
    # Stop SSH
    kill $SSH_PID 2>/dev/null || true
    
    echo "Shutdown complete"
    exit 0
}

trap shutdown_handler SIGTERM SIGINT

# Update hostname configuration if needed
CURRENT_HOSTNAME=$(hostname)
echo "Current hostname: $CURRENT_HOSTNAME"

if [ -d "/home/gpdata/coordinator/gpseg-1" ] && [ "$CURRENT_HOSTNAME" != "greenplum-sne" ]; then
    echo "Updating cluster configuration for hostname: $CURRENT_HOSTNAME"
    
    # Update postgresql.conf
    COORD_DIR="/home/gpdata/coordinator/gpseg-1"
    if [ -f "$COORD_DIR/postgresql.conf" ]; then
        sudo -u gpadmin sed -i "s/listen_addresses = .*/listen_addresses = '*'/" "$COORD_DIR/postgresql.conf" || true
    fi
    
    # Update gp_segment_configuration in single-user mode
    sudo -u gpadmin bash -c "
        source /usr/local/greenplum-db/greenplum_path.sh 2>/dev/null || true
        export COORDINATOR_DATA_DIRECTORY=$COORD_DIR
        export PGPORT=5432
        
        if [ -f \$GPHOME/bin/postgres ]; then
            timeout 30s \$GPHOME/bin/postgres --single -D $COORD_DIR template1 <<EOF 2>/dev/null || true
UPDATE gp_segment_configuration SET hostname='$CURRENT_HOSTNAME' WHERE hostname != '$CURRENT_HOSTNAME';
EOF
        fi
    " 2>/dev/null || true
fi

# Start Greenplum database
echo "Starting Greenplum database..."
sudo -u gpadmin bash << 'STARTUP_SCRIPT'
set -e
cd /home/gpadmin

# Source Greenplum environment
source /usr/local/greenplum-db/greenplum_path.sh

# Set required environment variables
export COORDINATOR_DATA_DIRECTORY=/home/gpdata/coordinator/gpseg-1
export PGPORT=5432

# Check if database is already running
if ! gpstate -s > /dev/null 2>&1; then
    echo "Starting Greenplum cluster..."
    gpstart -a
    
    # Wait a moment for full startup
    sleep 5
    
    # Verify database is accessible
    echo "Verifying database connection..."
    psql -d postgres -c "SELECT 'Greenplum database ready!' as status;"
else
    echo "Greenplum cluster is already running"
fi

# Show cluster status
echo "=== Greenplum Cluster Status ==="
gpstate -s

echo "=== Connection Information ==="
echo "Host: localhost (or container IP)"
echo "Port: 5432 (internal), 15432 (external via port mapping)"
echo "Database: postgres"
echo "Username: gpadmin"
echo "Password: VMware1!"
echo ""
echo "Connect externally with: psql -h localhost -p 15432 -U gpadmin -d postgres"

STARTUP_SCRIPT

echo "=== Greenplum Container Ready ==="

# Keep container running and monitor Greenplum
while true; do
    # Check if Greenplum is still running every 30 seconds
    if ! sudo -u gpadmin bash -c "
        source /usr/local/greenplum-db/greenplum_path.sh 2>/dev/null
        export COORDINATOR_DATA_DIRECTORY=/home/gpdata/coordinator/gpseg-1
        gpstate -s > /dev/null 2>&1
    "; then
        echo "WARNING: Greenplum appears to have stopped"
        echo "Attempting to restart..."
        sudo -u gpadmin bash -c "
            source /usr/local/greenplum-db/greenplum_path.sh
            export COORDINATOR_DATA_DIRECTORY=/home/gpdata/coordinator/gpseg-1
            gpstart -a
        " || true
    fi
    
    sleep 30
done