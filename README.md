# Greenplum Single Node Container

A clean, minimal Docker container for running Greenplum Database 7.x in single-node mode.

## Features

- ✅ Single-node Greenplum 7.x database
- ✅ Ready-to-use PostgreSQL-compatible interface
- ✅ Clean, organized container structure
- ✅ No unnecessary extensions or components
- ✅ Fast startup (~2-3 minutes)

## Prerequisites

1. **Greenplum RPM**: Download the Greenplum Database RPM from [VMware Tanzu Network](https://network.tanzu.vmware.com/products/vmware-tanzu-greenplum)
2. **Docker**: Ensure Docker is installed and running
3. **Platform**: Linux/amd64 (macOS with Apple Silicon uses emulation)

## Quick Start

### 1. Get Greenplum RPM

Download the Greenplum Database RPM file and place it in the `files/` directory:

```bash
# Example filename (adjust for your version)
files/greenplum-db-7.5.4-el9-x86_64.rpm
```

### 2. Build Container

```bash
./build-container.sh
```

### 3. Run Container

```bash
docker run -d -p 15432:5432 --hostname greenplum-sne --name greenplum-sne greenplum-db:7.5.4
```

### 4. Connect to Database

```bash
psql -h localhost -p 15432 -U gpadmin -d postgres
# Password: VMware1!
```

## Project Structure

```
greenplum-sne/
├── build-container.sh          # Main build script
├── container/
│   └── Dockerfile             # Container definition
├── scripts/
│   ├── install-greenplum.sh   # Database installation script
│   └── startup.sh             # Container startup script
├── files/                     # Place Greenplum RPM here
└── README.md                  # This file
```

## Configuration

### Default Settings

- **Database**: postgres
- **User**: gpadmin
- **Password**: VMware1!
- **Internal Port**: 5432
- **External Port**: 15432 (via port mapping)
- **Hostname**: greenplum-sne

### Container Specifications

- **Base Image**: Rocky Linux 9
- **Platform**: linux/amd64
- **Exposed Ports**: 5432 (PostgreSQL, mapped to 15432), 6000-6010 (Segments), 22 (SSH)

## Usage Examples

### Basic Connection

```bash
# Using psql
psql -h localhost -p 15432 -U gpadmin -d postgres

# Using connection string
psql "postgresql://gpadmin:VMware1!@localhost:15432/postgres"
```

### Create Sample Data

```sql
-- Create a simple table
CREATE TABLE sales (
    id SERIAL PRIMARY KEY,
    product VARCHAR(100),
    amount DECIMAL(10,2),
    sale_date DATE
) DISTRIBUTED BY (id);

-- Insert sample data
INSERT INTO sales (product, amount, sale_date) VALUES
    ('Widget A', 99.99, '2024-01-15'),
    ('Widget B', 149.50, '2024-01-16'),
    ('Widget C', 79.25, '2024-01-17');

-- Query the data
SELECT * FROM sales;
```

## Container Management

### Start/Stop Container

```bash
# Start
docker start greenplum-sne

# Stop
docker stop greenplum-sne

# Remove
docker rm greenplum-sne
```

### View Logs

```bash
docker logs greenplum-sne
```

### Execute Commands in Container

```bash
# Get a shell
docker exec -it greenplum-sne bash

# Run as gpadmin user
docker exec -it greenplum-sne sudo -u gpadmin bash

# Check Greenplum status
docker exec greenplum-sne sudo -u gpadmin bash -c "source /usr/local/greenplum-db/greenplum_path.sh && gpstate -s"
```

## Troubleshooting

### Container Won't Start

1. Check Docker logs: `docker logs greenplum-sne`
2. Verify RPM file is present in `files/` directory
3. Ensure sufficient memory (minimum 2GB recommended)

### Can't Connect to Database

1. Wait for full startup (2-3 minutes)
2. Check if container is running: `docker ps`
3. Verify port mapping: `docker port greenplum-sne`
4. Test connection: `docker exec greenplum-sne sudo -u gpadmin psql -d postgres -c "SELECT version();"`

### Performance Issues

- Allocate more CPU and memory to Docker
- Consider using persistent volumes for data storage
- Monitor container resources: `docker stats greenplum-sne`

## Development

This container is designed as a foundation for:
- Development and testing
- Adding Greenplum extensions (PXF, MADlib, etc.)
- Creating multi-container deployments
- CI/CD pipelines requiring Greenplum

## License

This project follows the same licensing terms as Greenplum Database. Consult VMware's licensing documentation for details.