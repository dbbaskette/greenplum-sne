# 🚀 Greenplum Single Node Environment (SNE) for Docker

Welcome to the Greenplum Single Node Environment (SNE) for Docker! This project provides a clean, minimal, and easy-to-use Docker container for running a single-node instance of **Greenplum Database 7.x**. It's perfect for development, testing, and learning.

> 💡 **Official Documentation**: For in-depth installation and configuration details, always refer to the official **[VMware Tanzu Greenplum Documentation](https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-greenplum/7/greenplum-database/install_guide-install_gpdb.html)**.

## ✨ Key Features

- ✅ **Single-Node Greenplum 7.x**: A fully functional Greenplum database instance.
- ✅ **PostgreSQL Interface**: Connect using standard PostgreSQL tools.
- ✅ **Clean & Minimal**: No unnecessary extensions or components, just the essentials.
- ✅ **Fast Startup**: Get up and running in approximately 2-3 minutes.
- ✅ **Cross-Platform**: Works on any Docker-enabled machine (Linux, macOS, Windows).

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

## ⚙️ Default Configuration

-   **Database**: `postgres`
-   **User**: `gpadmin`
-   **Password**: `VMware1!`
-   **Internal Port**: `5432`
-   **External Port**: `15432`
-   **Hostname**: `greenplum-sne`

---

## 🛠️ Container Management

### View Logs

Check the container logs to monitor the startup process and troubleshoot issues.

```bash
docker logs -f greenplum-sne
```

### Start, Stop, and Remove

```bash
# Start the container
docker start greenplum-sne

# Stop the container
docker stop greenplum-sne

# Remove the container (deletes all data unless using volumes)
docker rm greenplum-sne
```

### Access the Container Shell

Get an interactive shell inside the running container.

```bash
# Connect as the root user
docker exec -it greenplum-sne bash

# Connect as the gpadmin user
docker exec -it greenplum-sne sudo -u gpadmin bash
```

### Check Greenplum Status

Run this command to check the status of the Greenplum database inside the container.

```bash
docker exec -it greenplum-sne sudo -u gpadmin bash -c "source /usr/local/greenplum-db/greenplum_path.sh && gpstate -s"
```

---

## 🧪 Example: Create and Query a Table

Once connected, you can run standard SQL commands.

```sql
-- Create a distributed table
CREATE TABLE sales (
    id SERIAL PRIMARY KEY,
    product VARCHAR(100),
    amount DECIMAL(10,2),
    sale_date DATE
) DISTRIBUTED BY (id);

-- Insert some data
INSERT INTO sales (product, amount, sale_date) VALUES
    ('Laptop', 1200.00, '2025-01-15'),
    ('Mouse', 25.50, '2025-01-16'),
    ('Keyboard', 75.00, '2025-01-17');

-- Query the data
SELECT * FROM sales;
```

---

## 🏗️ How the Build Process Works

This project uses a **multi-stage build approach** that creates committed Docker images for fast, repeatable deployments.

### Build Process Overview

When you run `./build-container.sh`, here's what happens:

1. **Base Layer Creation**: Builds `greenplum-base:7.x.x` with Rocky Linux 9 + all dependencies
2. **Installation Container**: Runs a temporary container with hostname `greenplum-sne` 
3. **Greenplum Installation**: Installs and configures Greenplum database inside the running container
4. **Automatic Commit**: **Commits the running container** to `greenplum-db:7.x.x` 
5. **Cleanup**: Removes temporary build containers, leaving you with a ready-to-use base image

### Why This Approach?

**🚀 Fast Startup**: Instead of installing Greenplum every time you run a container (5+ minutes), the database is pre-installed and committed. New containers start in ~30 seconds.

**📦 Layered Architecture**: Creates a clean base image that can be extended for different use cases:

```dockerfile
# Example: Adding PXF to the base
FROM greenplum-sne-base:latest
COPY pxf-files/ /tmp/
RUN /tmp/install-pxf.sh
```

**🔄 Reproducible Builds**: The same build process creates identical images every time.

**🎯 Ready for Extensions**: The committed base image serves as a foundation for:
- **PXF** (Platform Extension Framework)  
- **MADlib** (Machine Learning)
- **PostGIS** (Spatial Database)
- **Custom applications and tools**

### Available Images After Build

After running the build script, you'll have:

- **`greenplum-db:7.x.x`** - Version-specific committed image
- **`greenplum-db:latest`** - Same image tagged as latest

For project work, you can create a more descriptive tag:
```bash
docker tag greenplum-db:7.5.4 greenplum-sne-base:latest
```

This gives you a solid, tested foundation for building PlumChat and other Greenplum-based applications! 🎯

---

## 📄 License

This project is provided as-is. The Greenplum Database software contained within the Docker image is subject to its own licensing terms. Please consult the official VMware Tanzu Greenplum documentation for details.