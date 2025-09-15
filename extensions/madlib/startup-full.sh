#!/bin/bash

# Startup script for Greenplum SNE with PXF and MADlib
# Extends the base startup with both PXF and MADlib support

set -e

echo "=== Starting Greenplum SNE with PXF and MADlib ==="
echo "Timestamp: $(date)"
echo ""

# Update hostname configuration (for container portability)
CURRENT_HOSTNAME=$(hostname)
if [ "$CURRENT_HOSTNAME" != "greenplum-sne" ]; then
    echo "Updating hostname configuration from $CURRENT_HOSTNAME to greenplum-sne..."
    
    # Update system files
    hostnamectl set-hostname greenplum-sne 2>/dev/null || echo "greenplum-sne" > /etc/hostname
    
    # Update /etc/hosts
    sed -i "s/$CURRENT_HOSTNAME/greenplum-sne/g" /etc/hosts
    
    # Update Greenplum configuration files as gpadmin
    sudo -u gpadmin bash -c "
        source /usr/local/greenplum-db/greenplum_path.sh
        
        # Update hostnames in Greenplum configuration
        find /home/gpadmin/gpconfigs -name '*.conf' -type f -exec sed -i 's/$CURRENT_HOSTNAME/greenplum-sne/g' {} \; 2>/dev/null || true
        find /home/gpadmin/gpdb_segments -name '*.conf' -type f -exec sed -i 's/$CURRENT_HOSTNAME/greenplum-sne/g' {} \; 2>/dev/null || true
    "
fi

# Start SSH daemon
echo "Starting SSH daemon..."
/usr/sbin/sshd

# Set environment variables for PXF
export PXF_HOME=/usr/local/pxf-gp7
export PXF_BASE=/home/gpadmin/pxf
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk

# Start Greenplum as gpadmin
echo "Starting Greenplum database..."
sudo -u gpadmin bash -c "
    source /usr/local/greenplum-db/greenplum_path.sh
    export PXF_HOME=$PXF_HOME
    export PXF_BASE=$PXF_BASE
    export JAVA_HOME=$JAVA_HOME
    export COORDINATOR_DATA_DIRECTORY=/home/gpdata/coordinator/gpseg-1
    export PGPORT=5432
    export PATH=\$PXF_HOME/bin:\$PATH
    
    # Start Greenplum
    gpstart -a
    
    # Wait for Greenplum to be fully started
    sleep 10
    
    # Initialize PXF if not already done
    if [ ! -f \$PXF_BASE/clusters/default/conf/cluster.txt ]; then
        echo 'Initializing PXF cluster configuration...'
        pxf cluster prepare || echo 'PXF cluster prepare failed'
        pxf cluster init || echo 'PXF cluster init failed'
    fi
    
    # Start PXF cluster
    echo 'Starting PXF cluster...'
    pxf cluster start || echo 'PXF cluster start failed or already running'
    
    # Create MADlib extension in postgres database if not exists
    echo 'Checking MADlib extension...'
    psql -d postgres -c \"CREATE EXTENSION IF NOT EXISTS madlib CASCADE;\" 2>/dev/null || echo 'MADlib extension already exists or creation failed'
    
    echo '✅ Greenplum database with PXF and MADlib is ready!'
    echo 'Connection details:'
    echo '  Host: localhost (or container IP)'
    echo '  Port: 5432'
    echo '  User: gpadmin'
    echo '  Password: VMware1!'
    echo '  Database: postgres'
    echo ''
    echo 'PXF Status:'
    pxf cluster status || echo 'Unable to get PXF status'
    echo ''
    echo 'MADlib Status:'
    psql -d postgres -t -c \"SELECT madlib.version();\" 2>/dev/null || echo 'MADlib not yet initialized'
"

# Keep container running and monitor processes
echo ""
echo "Container is ready. Monitoring processes..."

# Function to check if Greenplum is running
check_greenplum() {
    sudo -u gpadmin bash -c "
        source /usr/local/greenplum-db/greenplum_path.sh
        export COORDINATOR_DATA_DIRECTORY=/home/gpdata/coordinator/gpseg-1
        gpstate -s >/dev/null 2>&1
    "
}

# Function to check if PXF is running  
check_pxf() {
    sudo -u gpadmin bash -c "
        source /usr/local/greenplum-db/greenplum_path.sh
        export PXF_HOME=$PXF_HOME
        export PXF_BASE=$PXF_BASE
        export JAVA_HOME=$JAVA_HOME
        export PATH=\$PXF_HOME/bin:\$PATH
        pxf cluster status 2>/dev/null | grep -q 'PXF is running'
    "
}

# Monitor loop
while true; do
    sleep 30
    
    # Check Greenplum status
    if ! check_greenplum; then
        echo "⚠️  Greenplum appears to be down. Attempting restart..."
        sudo -u gpadmin bash -c "
            source /usr/local/greenplum-db/greenplum_path.sh
            export COORDINATOR_DATA_DIRECTORY=/home/gpdata/coordinator/gpseg-1
            gpstart -a
        "
    fi
    
    # Check PXF status
    if ! check_pxf; then
        echo "⚠️  PXF appears to be down. Attempting restart..."
        sudo -u gpadmin bash -c "
            source /usr/local/greenplum-db/greenplum_path.sh
            export PXF_HOME=$PXF_HOME
            export PXF_BASE=$PXF_BASE  
            export JAVA_HOME=$JAVA_HOME
            export PATH=\$PXF_HOME/bin:\$PATH
            pxf cluster start
        "
    fi
done