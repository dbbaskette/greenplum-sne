# PXF Extension for Greenplum SNE

## Overview

This extension adds PXF (Platform Extension Framework) capabilities to the Greenplum Single Node Environment. PXF enables Greenplum to query external data sources including:

- HDFS (Hadoop Distributed File System)
- Amazon S3
- Azure Blob Storage
- JDBC data sources (PostgreSQL, MySQL, Oracle, etc.)
- Hive tables
- HBase tables

## Quick Start

### Building the PXF Extension

```bash
# Ensure you have the base Greenplum container built first
./build-container.sh

# Build the PXF extension
./build-pxf-extension.sh
```

### Running the PXF-Enabled Container

```bash
docker run -d \
  -p 15432:5432 \
  --hostname greenplum-sne \
  --name greenplum-sne-pxf \
  greenplum-sne-pxf:latest
```

### Connecting to the Database

```bash
psql -h localhost -p 15432 -U gpadmin -d postgres
# Password: VMware1!
```

## Architecture

The PXF extension builds on top of the `greenplum-sne-base:latest` image and adds:

1. **Java 11** - Required runtime for PXF
2. **PXF 7.0.0** - The Platform Extension Framework
3. **Cluster Configuration** - Single-node PXF cluster setup
4. **Auto-initialization** - PXF starts automatically with the container

## Components

### Files Added

- `/usr/local/pxf-gp7/` - PXF installation directory
- `/home/gpadmin/pxf/` - PXF runtime configuration (PXF_BASE)
- `/usr/local/bin/startup-pxf.sh` - Enhanced startup script with PXF support

### Environment Variables

- `PXF_HOME=/usr/local/pxf-gp7`
- `PXF_BASE=/home/gpadmin/pxf`
- `JAVA_HOME=/usr/lib/jvm/java-11-openjdk`

## Verifying PXF Installation

### Check PXF Status

```bash
docker exec greenplum-sne-pxf sudo -u gpadmin bash -c \
  "source /usr/local/greenplum-db/greenplum_path.sh && \
   export PXF_HOME=/usr/local/pxf-gp7 && \
   export PXF_BASE=/home/gpadmin/pxf && \
   export JAVA_HOME=/usr/lib/jvm/java-11-openjdk && \
   export PATH=\$PXF_HOME/bin:\$PATH && \
   pxf cluster status"
```

### Create PXF Extension in Database

```sql
-- Connect to the database first
psql -h localhost -p 15432 -U gpadmin -d postgres

-- Create the PXF extension
CREATE EXTENSION IF NOT EXISTS pxf;

-- Verify installation
\dx pxf
```

## Example Usage

### Creating an External Table for S3 Data

```sql
-- Example: Reading CSV data from S3
CREATE EXTERNAL TABLE s3_data (
    id INTEGER,
    name TEXT,
    value DECIMAL
)
LOCATION ('pxf://bucket-name/path/to/data.csv?PROFILE=s3:text')
FORMAT 'CSV';
```

### Creating an External Table for JDBC Source

```sql
-- Example: Connecting to PostgreSQL
CREATE EXTERNAL TABLE postgres_data (
    id INTEGER,
    name TEXT
)
LOCATION ('pxf://public.mytable?PROFILE=jdbc&SERVER=postgres_server')
FORMAT 'CUSTOM' (FORMATTER='pxfwritable_import');
```

## Configuration

### Adding Data Source Servers

Configuration files are stored in `/home/gpadmin/pxf/servers/`. To add a new server:

1. Enter the container:
```bash
docker exec -it greenplum-sne-pxf sudo -u gpadmin bash
```

2. Create a server configuration:
```bash
mkdir -p $PXF_BASE/servers/my_s3_server
```

3. Add configuration files as needed (e.g., `s3-site.xml` for S3 access)

4. Sync the configuration:
```bash
pxf cluster sync
```

## Troubleshooting

### PXF Not Starting

If PXF fails to start, check:

1. Java installation:
```bash
docker exec greenplum-sne-pxf java -version
```

2. PXF logs:
```bash
docker exec greenplum-sne-pxf ls -la /home/gpadmin/pxf/logs/
```

3. Restart PXF manually:
```bash
docker exec greenplum-sne-pxf sudo -u gpadmin bash -c \
  "source /usr/local/greenplum-db/greenplum_path.sh && \
   export PXF_HOME=/usr/local/pxf-gp7 && \
   export PXF_BASE=/home/gpadmin/pxf && \
   export JAVA_HOME=/usr/lib/jvm/java-11-openjdk && \
   export PATH=\$PXF_HOME/bin:\$PATH && \
   pxf cluster restart"
```

### Extension Not Found

If `CREATE EXTENSION pxf` fails, the extension files may need to be registered:

```bash
docker exec greenplum-sne-pxf bash -c \
  "cp /usr/local/pxf-gp7/gpextable/* /usr/local/greenplum-db/share/postgresql/extension/ && \
   chown gpadmin:gpadmin /usr/local/greenplum-db/share/postgresql/extension/pxf*"
```

## Image Details

- **Base Image**: `greenplum-sne-base:latest` (4.26GB)
- **PXF Image**: `greenplum-sne-pxf:7.5.4-pxf7.0.0` (~4.5GB)
- **Additional Space**: ~250MB for PXF and Java

## Next Steps

1. Configure external data sources in `/home/gpadmin/pxf/servers/`
2. Create external tables to access your data
3. Use PXF profiles for optimized data access
4. Monitor PXF performance through logs

## Resources

- [Official PXF Documentation](https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-greenplum-platform-extension-framework/6-6/gp-pxf/overview_pxf.html)
- [PXF Configuration Reference](https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-greenplum-platform-extension-framework/6-6/gp-pxf/cfg_server.html)
- [Supported Data Formats](https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-greenplum-platform-extension-framework/6-6/gp-pxf/access_overview.html)