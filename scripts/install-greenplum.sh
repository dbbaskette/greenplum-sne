#!/bin/bash

# Greenplum Database Installation Script
# Installs ONLY the core Greenplum database software without extensions

set -e

# Set up logging
exec > >(tee -a /tmp/greenplum-install.log)
exec 2>&1

echo "=== Greenplum Database Installation Started ==="
echo "Timestamp: $(date)"

# Get hostname
HOSTNAME=$(hostname)
echo "Hostname: $HOSTNAME"

# Update hosts file for proper hostname resolution
echo "127.0.0.1 localhost $HOSTNAME" >> /etc/hosts

# Find and install Greenplum RPM
echo "Installing Greenplum database..."
GREENPLUM_RPM=$(find /tmp -name "greenplum-db-*.rpm" | head -1)

if [ -z "$GREENPLUM_RPM" ]; then
    echo "ERROR: Greenplum RPM not found in /tmp"
    exit 1
fi

# Install additional Python packages to fix pkg_resources issue
echo "Installing additional Python packages..."
dnf install -y python3-setuptools python3-setuptools-wheel

# Install Python packages via pip 
echo "Installing Python packages via pip..."
pip3 install --upgrade pip
pip3 install --no-warn-script-location setuptools

echo "Installing RPM: $GREENPLUM_RPM"
rpm -ivh "$GREENPLUM_RPM"

# Detect version and set up GPHOME
VERSION=$(rpm -qa | grep greenplum-db | sed 's/greenplum-db-//' | sed 's/-.*//')
echo "Detected Greenplum version: $VERSION"

# Set up GPHOME environment
if [ -d "/usr/local/greenplum-db-$VERSION" ]; then
    export GPHOME="/usr/local/greenplum-db-$VERSION"
    ln -sf "/usr/local/greenplum-db-$VERSION" "/usr/local/greenplum-db"
else
    export GPHOME="/usr/local/greenplum-db"
fi

echo "GPHOME: $GPHOME"

# Set up gpadmin user environment
echo "Configuring gpadmin user environment..."
sudo -u gpadmin bash << 'GPADMIN_ENV'
cd /home/gpadmin

# Add Greenplum environment to bashrc
cat >> ~/.bashrc << 'EOF'
# Greenplum Environment
source /usr/local/greenplum-db/greenplum_path.sh
export COORDINATOR_DATA_DIRECTORY=/home/gpdata/coordinator/gpseg-1
export PGPORT=5432
export PGUSER=gpadmin
export PGDATABASE=postgres
EOF

# Source the environment for this session
source /usr/local/greenplum-db/greenplum_path.sh
export COORDINATOR_DATA_DIRECTORY=/home/gpdata/coordinator/gpseg-1
export PGPORT=5432
GPADMIN_ENV

# Create host files for single-node setup
echo "$HOSTNAME" > /tmp/hostfile_exkeys
echo "$HOSTNAME" > /tmp/hostfile_gpinitsystem

# Exchange SSH keys for single node
echo "Setting up SSH keys..."
sudo -u gpadmin bash -c "
source /usr/local/greenplum-db/greenplum_path.sh
gpssh-exkeys -f /tmp/hostfile_exkeys
"

# Create gpinitsystem configuration
echo "Creating Greenplum cluster configuration..."
cat > /tmp/gpinitsystem_config << EOF
# Greenplum Single Node Configuration
ARRAY_NAME="Greenplum Single Node"
SEG_PREFIX=gpseg
PORT_BASE=6000
declare -a DATA_DIRECTORY=(/home/gpdata/primary)
COORDINATOR_HOSTNAME=$HOSTNAME
COORDINATOR_DIRECTORY=/home/gpdata/coordinator
COORDINATOR_PORT=5432
TRUSTED_SHELL=ssh
CHECK_POINT_SEGMENTS=8
ENCODING=UNICODE
DATABASE_NAME=postgres
EOF

# Initialize Greenplum cluster
echo "Initializing Greenplum cluster..."
sudo -u gpadmin bash -c "
source /usr/local/greenplum-db/greenplum_path.sh
gpinitsystem -c /tmp/gpinitsystem_config -h /tmp/hostfile_gpinitsystem -a
"

# Configure pg_hba.conf for external connections
echo "Configuring database access..."
sudo -u gpadmin bash -c "
source /usr/local/greenplum-db/greenplum_path.sh
export COORDINATOR_DATA_DIRECTORY=/home/gpdata/coordinator/gpseg-1
export PGPORT=5432

# Allow connections from any IP (for container access)
echo 'host all all 0.0.0.0/0 trust' >> \$COORDINATOR_DATA_DIRECTORY/pg_hba.conf
echo 'host all all ::/0 trust' >> \$COORDINATOR_DATA_DIRECTORY/pg_hba.conf

# Update postgresql.conf for external access
sed -i \"s/#listen_addresses = 'localhost'/listen_addresses = '*'/\" \$COORDINATOR_DATA_DIRECTORY/postgresql.conf
sed -i \"s/listen_addresses = 'localhost'/listen_addresses = '*'/\" \$COORDINATOR_DATA_DIRECTORY/postgresql.conf

# Reload configuration
gpstop -u
"

echo "=== Greenplum Database Installation Completed ==="
echo "Database is ready to accept connections"