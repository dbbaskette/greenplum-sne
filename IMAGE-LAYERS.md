# Greenplum Docker Image Layers

## Current Images and Their Purpose

### 1. `greenplum-base:7.5.4` (2.6GB)
**What it is:** Rocky Linux 9 + all dependencies + gpadmin user setup
**Contents:**
- Rocky Linux 9 base OS
- All system packages (Python, Java, SSH, build tools, etc.)
- gpadmin user configured with SSH keys
- Data directories created
- NO Greenplum installed yet

**Purpose:** 
- Building block for creating new Greenplum variants
- Useful if you want to install different Greenplum versions
- Can be reused for experimental builds

**Do you need it?** Only if you plan to build different Greenplum configurations

### 2. `greenplum-sne-base:7.5.4` (4.26GB)
**What it is:** Base + Greenplum 7.5.4 installed and configured
**Contents:**
- Everything from `greenplum-base:7.5.4`
- Greenplum 7.5.4 installed and initialized
- Single-node cluster configured
- pg_hba.conf set for external access
- Ready to run immediately

**Purpose:**
- Version-specific tag of working Greenplum SNE
- Primary image for PlumChat development and extension layers

**Do you need it?** YES - This is your main base image (also tagged as `greenplum-sne-base:latest`)

## Recommendations

### Minimal Setup (Recommended):
Keep only what you need for PlumChat development:
```bash
# Keep this - your main base for extensions
greenplum-sne-base:7.5.4 (also tagged latest)

# Remove this to save 2.6GB:
docker rmi greenplum-base:7.5.4
```

### Development Setup:
If you plan to experiment with different Greenplum configurations:
```bash
# Keep both
greenplum-sne-base:7.5.4 (also tagged latest) - For PlumChat/PXF work
greenplum-base:7.5.4 (2.6GB) - For building new variants

# Optional cleanup:
# docker rmi greenplum-base:7.5.4
```

### Conservative Setup:
Keep everything if you're unsure:
```bash
# Both images - uses ~6.9GB total
```

## Usage Examples

### For PXF Extension:
```dockerfile
FROM greenplum-sne-base:latest
# Add PXF installation
```

### For Different Greenplum Version:
```dockerfile
FROM greenplum-base:7.5.4
# Install different Greenplum version
```

### For Experimental Features:
```dockerfile
FROM greenplum-base:7.5.4
# Install Greenplum with custom compile options
```

## Summary
- **Essential:** `greenplum-sne-base:7.5.4` (also `latest`)
- **Optional:** `greenplum-base:7.5.4` (if building variants)
