# Greenplum Base Image Information

## Known Good State - Ready for Extensions

**Image Tags:**
- `greenplum-db:7.5.4-base` - Clean Greenplum 7.5.4 database only
- `greenplum-sne-base:latest` - Same image with descriptive name

**Base Image Contents:**
- ✅ Rocky Linux 9 base OS
- ✅ Greenplum Database 7.5.4 (PostgreSQL 12.22)
- ✅ Single-node cluster configuration
- ✅ Port 5432 internal (map to 15432 external)
- ✅ gpadmin user with VMware1! password
- ✅ SSH access configured
- ✅ pg_hba.conf set for external trust authentication
- ✅ Database ready to accept connections immediately

**What's NOT included (ready to add):**
- PXF (Platform Extension Framework)
- MADlib (Machine Learning)
- PostGIS (Spatial database)
- Python extensions/packages
- Custom applications

## Usage as Base for Extensions

### For PXF Extension:
```dockerfile
FROM greenplum-sne-base:latest

# Add PXF installation steps
COPY pxf-files/ /tmp/
RUN /tmp/install-pxf.sh

# Override startup to include PXF startup
CMD ["/usr/local/bin/startup-with-pxf.sh"]
```

### For MADlib Extension:
```dockerfile
FROM greenplum-sne-base:latest

# Add MADlib installation
COPY madlib-files/ /tmp/
RUN /tmp/install-madlib.sh
```

## Verified Functionality

**Connection Test:**
```bash
psql -h localhost -p 15432 -U gpadmin -d postgres
```

**Table Operations:**
- CREATE TABLE with DISTRIBUTED BY
- INSERT/SELECT operations
- DROP TABLE
- All standard PostgreSQL/Greenplum operations

## Image Size
- **Base OS layer**: ~2.6GB (`greenplum-base:7.5.4`)
- **With Greenplum**: ~4.26GB (`greenplum-sne-base:latest`)
- **Available for extensions**: Plenty of room for PXF, MADlib, etc.

---
**Created**: September 15, 2025  
**Greenplum Version**: 7.5.4  
**Status**: Tested and verified working ✅