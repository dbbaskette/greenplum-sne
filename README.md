# 🚀 Greenplum Single Node Environment (SNE) for Docker

Welcome to the Greenplum Single Node Environment (SNE) for Docker! This project provides a clean, minimal, and easy-to-use Docker container for running a single-node instance of **Greenplum Database 7.x**. It's perfect for development, testing, and learning.

> 💡 **Official Documentation**: For in-depth installation and configuration details, always refer to the official **[VMware Tanzu Greenplum Documentation](https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-greenplum/7/greenplum-database/install_guide-install_gpdb.html)**.

## ✨ Key Features

- ✅ **Single-Node Greenplum 7.x**: A fully functional Greenplum database instance.
- ✅ **PostgreSQL Interface**: Connect using standard PostgreSQL tools.
- ✅ **Clean & Minimal**: No unnecessary extensions or components, just the essentials.
- ✅ **Fast Startup**: Get up and running in approximately 2-3 minutes.
- ✅ **Cross-Platform**: Works on any Docker-enabled machine (Linux, macOS, Windows).
- ✅ **PXF and MADlib Extensions**: Includes the Greenplum Platform Extension Framework (PXF) and MADlib for advanced analytics.

---

## 📋 Prerequisites

Before you begin, ensure you have the following:

1.  **🟢 Greenplum RPM**: You must download the Greenplum Database RPM file from the [VMware Tanzu Network](https://network.tanzu.vmware.com/products/vmware-tanzu-greenplum).
2.  **🐳 Docker**: Docker Desktop or Docker Engine must be installed and running.
3.  **🖥️ Platform**: The container runs a `linux/amd64` image. On Apple Silicon (M1/M2/M3) Macs, Docker will use Rosetta 2 for emulation.

### ⚠️ Important Note for Docker Desktop Users (macOS & Windows)

It is **required** to **enable the Docker VMM (Virtual Machine Manager) setting** in Docker Desktop for this container to work, especially on systems with Apple Silicon. This is a mandatory setting.

-   **To enable**: Go to **Docker Desktop > Settings > General** and select the appropriate VMM setting.
-   **Learn More**: Refer to the official Docker documentation for details on what this setting does and its impact on performance.

---

## 🚀 Getting Started

### 1. Download the Greenplum RPM

Place the Greenplum Database RPM file you downloaded into the `files/` directory. The build script will automatically pick it up.

```bash
# The filename will vary based on the version you download
mv ~/Downloads/greenplum-db-*.rpm files/
```

### 2. Build the Docker Container

Run the build script. This will create a Docker image tagged with the Greenplum version.

```bash
./build-container.sh
```

### 3. Run the Container

Launch the container in detached mode. This command maps the internal PostgreSQL port `5432` to `15432` on your local machine.

```bash
docker run -d \
  -p 15432:5432 \
  --hostname greenplum-sne \
  --name greenplum-sne \
  greenplum-db:7.x.x # 👈 Replace with the actual version from the build
```

### 4. Connect to the Database

You can now connect to the Greenplum database using `psql` or any other PostgreSQL-compatible client.

```bash
psql -h localhost -p 15432 -U gpadmin -d postgres
```

> **Password**: `VMware1!`

---

## 🧩 Extensions: PXF and MADlib

This project provides a layered approach to building containers with extensions. You can choose a base container, a container with PXF, or a full container with PXF and MADlib.

### PXF Extension

The Greenplum Platform Extension Framework (PXF) is included in this project, allowing you to connect to external data sources like S3, HDFS, and more.

**Building the PXF-Enabled Container**

To create a container with PXF, run the `build-pxf-extension.sh` script. This will create a new Docker image called `greenplum-db-pxf`.

```bash
./build-pxf-extension.sh
```

**Running the PXF-Enabled Container**

To run the container with PXF, use the `greenplum-db-pxf` image.

```bash
docker run -d \
  -p 15432:5432 \
  -p 5888:5888 \
  --hostname greenplum-sne-pxf \
  --name greenplum-sne-pxf \
  greenplum-db-pxf:7.x.x # 👈 Replace with the actual version from the build
```

For more information, refer to the `PXF-EXTENSION.md` file in this repository and the official [PXF Installation Documentation](https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-greenplum-platform-extension-framework/6-6/gp-pxf/installing_pxf.html).

### MADlib Extension

Apache MADlib is an open-source library for scalable in-database analytics.

**Building the Full Container (with MADlib)**

To create a container with both PXF and MADlib, run the `build-full-extensions.sh` script. This will create a new Docker image called `greenplum-sne-full`.

```bash
./build-full-extensions.sh
```

**Running the Full Container**

To run the container with PXF and MADlib, use the `greenplum-sne-full` image.

```bash
docker run -d \
  -p 15432:5432 \
  --hostname greenplum-sne-full \
  --name greenplum-sne-full \
  greenplum-sne-full:latest
```

**Verifying the MADlib Installation**

```bash
psql -h localhost -p 15432 -U gpadmin -d postgres -c "SELECT madlib.version();"
```

For more information, refer to the official [Apache MADlib Documentation](https://madlib.apache.org/).

---

## 🏗️ How the Build Process Works

This project uses a **multi-stage build approach** that creates committed Docker images for fast, repeatable deployments.

### Build Process Overview

1. **Base Layer Creation**: Builds `greenplum-base:7.x.x` with Rocky Linux 9 + all dependencies
2. **Installation Container**: Runs a temporary container with hostname `greenplum-sne` 
3. **Greenplum Installation**: Installs and configures Greenplum database inside the running container
4. **Automatic Commit**: **Commits the running container** to `greenplum-db:7.x.x` 
5. **Cleanup**: Removes temporary build containers, leaving you with a ready-to-use base image

### Available Images After Build

After running the build scripts, you'll have three sets of images:

- **`greenplum-db:7.x.x`**: The base Greenplum image without any extensions.
- **`greenplum-db-pxf:7.x.x`**: The Greenplum image with the PXF extension.
- **`greenplum-sne-full:latest`**: The Greenplum image with both PXF and MADlib.

This layered approach allows you to choose the image that best fits your needs.

---

## 📄 License

This project is provided as-is. The Greenplum Database software contained within the Docker image is subject to its own licensing terms. Please consult the official VMware Tanzu Greenplum documentation for details.