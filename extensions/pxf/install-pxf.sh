#!/bin/bash

# PXF Installation Script for Greenplum SNE
# Based on working implementation from ../gpdb_installer/lib/pxf.sh

set -e

echo "=== Installing PXF for Greenplum SNE ==="

# Source Greenplum environment
source /usr/local/greenplum-db/greenplum_path.sh

# Install PXF RPM
echo "Installing PXF RPM..."
rpm -ivh /tmp/pxf-gp7-7.0.0-2.el9.x86_64.rpm

# Set PXF environment variables
export PXF_HOME=/usr/local/pxf-gp7
export PXF_BASE=/home/gpadmin/pxf
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk

# Add PXF to PATH for gpadmin
echo 'export PXF_HOME=/usr/local/pxf-gp7' >> /home/gpadmin/.bashrc
echo 'export PXF_BASE=/home/gpadmin/pxf' >> /home/gpadmin/.bashrc
echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk' >> /home/gpadmin/.bashrc
echo 'export PATH=$PXF_HOME/bin:$PATH' >> /home/gpadmin/.bashrc

# Create PXF base directory structure
echo "Creating PXF base directory..."
mkdir -p $PXF_BASE
chown -R gpadmin:gpadmin $PXF_BASE

# Initialize PXF as gpadmin user
echo "Initializing PXF configuration..."
sudo -u gpadmin bash -c "
    source /usr/local/greenplum-db/greenplum_path.sh
    export PXF_HOME=/usr/local/pxf-gp7
    export PXF_BASE=/home/gpadmin/pxf
    export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
    export PATH=\$PXF_HOME/bin:\$PATH
    export GPHOME=/usr/local/greenplum-db
    
    # For single-node, create hostfile
    echo 'localhost' > /tmp/hostfile_singlenode
    
    # Prepare PXF configuration
    echo 'Running pxf cluster prepare...'
    pxf cluster prepare
    
    # Initialize PXF cluster
    echo 'Running pxf cluster init...'
    pxf cluster init
    
    echo 'PXF cluster initialized for single-node configuration'
"

# Set proper permissions
chown -R gpadmin:gpadmin $PXF_BASE
chmod -R 755 $PXF_BASE

echo "✅ PXF installation completed successfully!"
echo ""
echo "PXF Configuration:"
echo "  PXF_HOME: $PXF_HOME"
echo "  PXF_BASE: $PXF_BASE" 
echo "  JAVA_HOME: $JAVA_HOME"
echo ""
echo "Note: PXF will be started automatically when the container starts."