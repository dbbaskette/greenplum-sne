# 🌿 Greenplum SNE for Docker

Build lightning-fast single-node Greenplum 7.5.4 environments with curated analytics extensions.

![Greenplum](https://img.shields.io/badge/Greenplum-7.5.4-27AE60?style=for-the-badge&logo=postgresql&logoColor=white)
![PXF](https://img.shields.io/badge/PXF-7.0.0-1E90FF?style=for-the-badge)
![MADlib](https://img.shields.io/badge/MADlib-2.2.0-7F3FBF?style=for-the-badge)
![License](https://img.shields.io/badge/Use%20with-VMware%20Tanzu%20License-34495E?style=for-the-badge)

> 💡 **Official Documentation:** [VMware Tanzu Greenplum docs](https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-greenplum/7/greenplum-database/install_guide-install_gpdb.html)

## ✨ Features

- **Single-node Greenplum 7.5.4** - Perfect for development and testing
- **Three variants** - Base, PXF-enabled, or Full analytics stack
- **Unified scripts** - Simple `build-gpsne.sh` and `run-gpsne.sh` commands
- **Pre-configured** - SSH trust, cluster initialized, ready to connect
- **Analytics ready** - Includes pgvector, MADlib ML, Python data science tools

## ⚡ Quick Start

### Prerequisites

1. **Download Greenplum RPM** from VMware Tanzu and place in `files/`
2. **Docker Desktop** with linux/amd64 support
3. **Optional extras** for full build:
   - PXF RPM: `pxf-gp7-7.0.0-2.el9.x86_64.rpm`
   - MADlib: `madlib-2.2.0-gp7-el9-x86_64.tar.gz`

### Build & Run

```bash
# Build the base container
./build-gpsne.sh --base

# Run it
./run-gpsne.sh --base

# Connect
psql -h localhost -p 15432 -U gpadmin -d postgres
# Password: VMware1!
```

## 🎯 Container Variants

| Variant | Build Command | Run Command | Features |
|---------|--------------|-------------|----------|
| **Base** | `./build-gpsne.sh --base` | `./run-gpsne.sh --base` | Core Greenplum + pgvector |
| **PXF** | `./build-gpsne.sh --pxf` | `./run-gpsne.sh --pxf` | + External data access |
| **Full** | `./build-gpsne.sh --full` | `./run-gpsne.sh --full` | + MADlib ML + Python libs |

## 📦 Build Options

```bash
# Build specific variant
./build-gpsne.sh --base    # Base Greenplum
./build-gpsne.sh --pxf     # With PXF extension
./build-gpsne.sh --full    # Full analytics stack

# Build all variants
./build-gpsne.sh --all

# Additional options
./build-gpsne.sh --full --no-cache         # Force rebuild
./build-gpsne.sh --full --keep-intermediate # Keep PXF image

# Management commands
./build-gpsne.sh --status  # Check image status
./build-gpsne.sh --clean   # Remove all images
```

## 🚀 Run Options

```bash
# Start containers
./run-gpsne.sh --base    # Run base variant
./run-gpsne.sh --pxf     # Run PXF variant (port 5888 for PXF API)
./run-gpsne.sh --full    # Run full variant (default)

# Container management
./run-gpsne.sh --stop    # Stop all containers
./run-gpsne.sh --status  # Check container status
./run-gpsne.sh --logs    # View container logs

# Specific container operations
./run-gpsne.sh --stop --pxf   # Stop only PXF container
./run-gpsne.sh --logs --full  # View only full container logs
```

## 🔌 Connection Details

- **Host:** localhost
- **Port:** 15432
- **User:** gpadmin
- **Password:** VMware1!
- **Database:** postgres

### PXF API (PXF variant only)
- **URL:** http://localhost:5888

## 🧩 Extension Features

### Base Container
- Greenplum Database 7.5.4
- pgvector 0.7.0 for similarity search
- PL/Python3U with Python 3.11

### PXF Container
- Everything from Base
- PXF 7.0.0 for external data access
- Java 11 runtime
- Connectors for S3, HDFS, JDBC, Hive

### Full Container
- Everything from PXF
- MADlib 2.2.0 for in-database ML
- NumPy, pandas, scikit-learn
- Matplotlib for visualization

## 🛠️ Verify Installation

```bash
# Check extensions
psql -h localhost -p 15432 -U gpadmin -d postgres -c "\dx"

# Test pgvector
psql -h localhost -p 15432 -U gpadmin -d postgres -c \
  "SELECT '[1,2,3]'::vector <-> '[4,5,6]'::vector;"

# Check MADlib (full container)
psql -h localhost -p 15432 -U gpadmin -d postgres -c \
  "SELECT madlib.version();"

# Check PXF status (PXF/full containers)
docker exec greenplum-sne-pxf bash -c \
  "source /usr/local/greenplum-db/greenplum_path.sh && \
   pxf cluster status"
```

## 📁 Project Structure

```
greenplum-sne/
├── build-gpsne.sh           # Unified build script
├── run-gpsne.sh            # Unified run script
├── container/
│   └── Dockerfile          # Base container definition
├── scripts/
│   ├── install-greenplum.sh
│   └── startup.sh
├── extensions/
│   ├── pxf/               # PXF extension files
│   └── madlib/            # MADlib extension files
└── files/                 # Place RPMs and archives here
```

## 🔧 Troubleshooting

### Build Issues
- **RPM not found:** Ensure Greenplum RPM is in `files/` directory
- **Build fails:** Try `./build-gpsne.sh --clean` then rebuild
- **Out of space:** Check Docker disk usage, prune old images

### Runtime Issues
- **Port conflict:** Change port mapping or stop conflicting service
- **Container won't start:** Check logs with `./run-gpsne.sh --logs`
- **Can't connect:** Verify container is running with `./run-gpsne.sh --status`

### Extension Issues
- **PXF not running:** Check Java with `docker exec <container> java -version`
- **MADlib missing:** Re-create extension with `CREATE EXTENSION madlib CASCADE;`

## 📚 Documentation

- [PXF Extension Guide](PXF-EXTENSION.md) - External data configuration
- [MADlib Extension Guide](MADLIB-EXTENSION.md) - Machine learning examples
- [Image Layers](IMAGE-LAYERS.md) - Container architecture details

## 📄 License

This project provides automation for building Greenplum containers. The included Greenplum Database, PXF, and MADlib remain subject to their respective VMware Tanzu and Apache licenses. Review and comply with all vendor terms before use or redistribution.