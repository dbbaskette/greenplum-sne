#!/bin/bash

# MADlib Installation Script for Greenplum SNE
# Installs MADlib machine learning library

set -e

echo "=== Installing MADlib for Greenplum SNE ==="

# Source Greenplum environment
source /usr/local/greenplum-db/greenplum_path.sh

# Extract MADlib archive
echo "Extracting MADlib archive..."
cd /tmp
tar -xzf madlib-2.2.0-gp7-el9-x86_64.tar.gz
cd madlib-2.2.0-gp7-el9-x86_64

# Extract the gppkg file
echo "Extracting MADlib gppkg..."
tar -xzf madlib-2.2.0-gp7-el9-x86_64.gppkg.tar.gz -C /tmp/
mv /tmp/share /tmp/madlib-share 2>/dev/null || true
mv /tmp/lib /tmp/madlib-lib 2>/dev/null || true
mv /tmp/usr /tmp/madlib-usr 2>/dev/null || true

# Copy MADlib files to Greenplum directories
echo "Installing MADlib files..."

# Copy library files
if [ -d "/tmp/madlib-lib" ]; then
    echo "Copying library files..."
    cp -r /tmp/madlib-lib/* /usr/local/greenplum-db/lib/
fi

# Copy share files (includes extension SQL files)
if [ -d "/tmp/madlib-share" ]; then
    echo "Copying share files..."
    cp -r /tmp/madlib-share/* /usr/local/greenplum-db/share/
    
    # List what was copied for debugging
    echo "Extension files copied:"
    ls -la /usr/local/greenplum-db/share/postgresql/extension/madlib* 2>/dev/null || echo "No madlib extension files found"
fi

# Copy usr files if present
if [ -d "/tmp/madlib-usr" ]; then
    echo "Copying usr files..."
    cp -r /tmp/madlib-usr/* /usr/
fi

# Process SQL template files as specified in pkgspec.yaml
echo "Processing MADlib SQL templates..."
find /usr/local/greenplum-db/share -name "madlib--*.sql.in" | while read template; do
    output="${template%.in}"
    cp "$template" "$output"
    sed -i "s#MADLIB_SHAREDIR#/usr/local/greenplum-db/share/madlib/modules#g" "$output"
done

# Install Python data science packages for PL/Python3U
echo "Installing Python data science packages..."

# Ensure pip is available for Python 3.11 (used by PL/Python3U)
python3.11 -m ensurepip --upgrade 2>/dev/null || echo "pip already available for Python 3.11"

# Install packages for Python 3.11 (PL/Python3U environment)
python3.11 -m pip install --no-cache-dir numpy scikit-learn pandas scipy matplotlib

echo "Python packages installed for PL/Python3U"

# Set proper ownership
chown -R gpadmin:gpadmin /usr/local/greenplum-db/lib/madlib* 2>/dev/null || true
chown -R gpadmin:gpadmin /usr/local/greenplum-db/share/postgresql/extension/madlib* 2>/dev/null || true
chown -R gpadmin:gpadmin /usr/local/greenplum-db/share/madlib 2>/dev/null || true

# Clean up
cd /
rm -rf /tmp/madlib-2.2.0-gp7-el9-x86_64
rm -rf /tmp/madlib-share /tmp/madlib-lib /tmp/madlib-usr /tmp/pkgspec.yaml

echo "✅ MADlib installation completed successfully!"
echo ""
echo "MADlib Configuration:"
echo "  Version: 2.2.0"
echo "  Greenplum Version: 7"
echo ""
echo "Python Data Science Packages:"
echo "  - NumPy (arrays and numerical computing)"
echo "  - scikit-learn (machine learning)"
echo "  - pandas (data manipulation)"
echo "  - SciPy (scientific computing)"
echo "  - matplotlib (plotting)"
echo ""
echo "To enable MADlib in a database, run:"
echo "  CREATE EXTENSION madlib CASCADE;"