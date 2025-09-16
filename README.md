<h1 align="center">🌿 <span style="color:#3CB371;font-family:'Poppins',sans-serif;">Greenplum SNE</span> <span style="color:#1E90FF;font-family:'Fira Code',monospace;">for Docker</span></h1>
<p align="center" style="font-size:1.1rem;">
  Build lightning-fast single-node <strong>Greenplum 7.5.4</strong> environments with curated analytics extensions.<br/>
  <span style="color:#FF8A00;">PXF</span> • <span style="color:#7B61FF;">MADlib</span> • <span style="color:#00C49A;">pgvector</span> • <span style="color:#F45B69;">Python 3.11 Data Science Stack</span>
</p>

<p align="center">
  <img alt="Greenplum" src="https://img.shields.io/badge/Greenplum-7.5.4-27AE60?style=for-the-badge&logo=postgresql&logoColor=white"/>
  <img alt="PXF" src="https://img.shields.io/badge/PXF-7.0.0-1E90FF?style=for-the-badge"/>
  <img alt="MADlib" src="https://img.shields.io/badge/MADlib-2.2.0-7F3FBF?style=for-the-badge"/>
  <img alt="License" src="https://img.shields.io/badge/Use%20with-VMware%20Tanzu%20License-34495E?style=for-the-badge"/>
</p>

> 💡 <strong>Official Documentation:</strong> Always consult the <a href="https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-greenplum/7/greenplum-database/install_guide-install_gpdb.html">VMware Tanzu Greenplum docs</a> for production guidance.

---

## 📄 Table of Contents
- [Why SNE?](#-why-sne)
- [Image Lineup](#-image-lineup)
- [Quick Start](#-quick-start)
- [Choose Your Adventure](#-choose-your-adventure)
- [Connect & Verify](#-connect--verify)
- [How It Works](#-how-it-works)
- [Project Atlas](#-project-atlas)
- [Troubleshooting](#-troubleshooting)
- [Resources](#-resources)
- [License](#-license)

---

## ✨ Why SNE?
- ✅ **Single-node, testing instance of Greenplum** built on Rocky Linux 9.
- ⚙️ **Automated provisioning** via `scripts/install-greenplum.sh` with SSH trust, cluster init, and open network access baked in.
- 🧩 **Composable layers**: start minimal, stack on PXF (external data), MADlib (ML), pgvector, and preloaded Python data science goodies.
- 🚀 **Fast feedback loop**: build → commit → run in minutes thanks to opinionated Docker scripts.
- 🛠️ **Developer focused**: perfect for demos, integration tests, AI/ML prototypes, or learning the Greenplum MPP architecture.

### Feature Highlights
| Layer | Included Goodies | Notes |
| --- | --- | --- |
| <span style="color:#3CB371;font-weight:bold;">Base</span> | Greenplum 7.5.4, pgvector 0.7.0, PL/Python3U, SSH | Minimal core database image (`greenplum-db:7.5.4`, tag as `greenplum-sne-base:latest`) |
| <span style="color:#1E90FF;font-weight:bold;">PXF</span> | Java 11, PXF 7.0.0, auto cluster start | External tables to S3, HDFS, JDBC, Hive, more |
| <span style="color:#7B61FF;font-weight:bold;">Full</span> | MADlib 2.2.0, NumPy 2.3, pandas 2.3, scikit-learn 1.7, matplotlib 3.10 | End-to-end analytics & vector stack |

---

## 🧱 Image Lineup
| Tag | Size* | Purpose | Ports |
| --- | --- | --- | --- |
| `greenplum-base:7.5.4` | ~2.6 GB | Rocky Linux + dependencies + `gpadmin` user. No DB yet. | 22 |
| `greenplum-db:7.5.4` + `greenplum-sne-base:latest` | ~4.3 GB | Ready-to-run Greenplum with pgvector + Python 3.11. | 22, 5432, 6000-6010 |
| `greenplum-sne-pxf:latest` | ~4.5 GB | Adds Java + PXF + orchestration. | 22, 5432, 5888, 6000-6010 |
| `greenplum-sne-full:latest` | ~4.5 GB | Full analytics stack: PXF + MADlib + pgvector + PyData. | 22, 5432, 5888, 6000-6010 |

<sub>*Sizes are approximate compressed image footprints.</sub>

> 🧭 <strong>Versioning:</strong> Check the repository <code>VERSION</code> file (current <code>0.0.5</code>) for project release tracking.

---

## ⚡ Quick Start

<div align="center" style="padding:1rem;border:2px solid #3CB371;border-radius:12px;background:linear-gradient(120deg,#e6fffa,#f0f4ff);">
<pre style="text-align:left;margin:0;">
<span style="color:#3CB371;"># 1 ─ Download Greenplum RPM</span>
mv ~/Downloads/greenplum-db-7.5.4-*.rpm files/

<span style="color:#1E90FF;"># 2 ─ Build the base image</span>
./build-container.sh

<span style="color:#FF8A00;"># 3 ─ Alias for extension builds</span>
docker tag greenplum-db:7.5.4 greenplum-sne-base:latest

<span style="color:#7B61FF;"># 4 ─ Run the container</span>
docker run -d \
  -p 15432:5432 \
  --hostname greenplum-sne \
  --name greenplum-sne \
  greenplum-db:7.5.4
</pre>
</div>

> 🔑 Default credentials → user: <code>gpadmin</code> • password: <code>VMware1!</code> • database: <code>postgres</code>

### Prerequisites Checklist
- 🟩 <strong>Greenplum RPM</strong> placed in `files/` (`greenplum-db-7.5.4-el9-x86_64.rpm`).
- 🟦 <strong>Docker</strong> Desktop/Engine (with the VMM option enabled on macOS/Windows).
- 🟥 <strong>Architecture</strong>: `linux/amd64` (Apple Silicon uses Rosetta 2 emulation).
- 🟨 Optional extras in `files/`: `pxf-gp7-7.0.0-2.el9.x86_64.rpm`, `madlib-2.2.0-gp7-el9-x86_64.tar.gz`.

---

## 🧭 Choose Your Adventure

<table>
  <thead>
    <tr>
      <th style="text-align:left;">Scenario</th>
      <th style="text-align:left;">Build Command</th>
      <th style="text-align:left;">Resulting Image</th>
      <th style="text-align:left;">Best For</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>🚦 Minimal database (fastest)</td>
      <td><code>./build-container.sh</code><br/><code>docker tag greenplum-db:7.5.4 greenplum-sne-base:latest</code></td>
      <td><code>greenplum-db:7.5.4</code> + <code>greenplum-sne-base:latest</code></td>
      <td>SQL development, pgvector prototypes</td>
    </tr>
    <tr>
      <td>🌐 External data connectivity</td>
      <td><code>./build-pxf-extension.sh</code></td>
      <td><code>greenplum-sne-pxf:latest</code></td>
      <td>S3/HDFS/Hive/JDBC federated queries</td>
    </tr>
    <tr>
      <td>🧠 Full analytics lab</td>
      <td><code>./build-full-extensions.sh</code></td>
      <td><code>greenplum-sne-full:latest</code></td>
      <td>MADlib ML, vector search, Python data science</td>
    </tr>
  </tbody>
</table>

### Example Runtime Commands
```bash
# PXF-enabled container (adds 5888 for PXF REST API)
docker run -d \
  -p 15432:5432 -p 5888:5888 \
  --hostname greenplum-sne-pxf \
  --name greenplum-sne-pxf \
  greenplum-sne-pxf:latest

# Full analytics container
docker run -d \
  -p 15432:5432 \
  --hostname greenplum-sne-full \
  --name greenplum-sne-full \
  greenplum-sne-full:latest
```

---

## 🔌 Connect & Verify

```bash
# Connect with psql
psql -h localhost -p 15432 -U gpadmin -d postgres

# List installed extensions
\dx

# Check MADlib + vector functionality (full image)
SELECT madlib.version();
SELECT '[1,2,3]'::vector <-> '[4,5,6]'::vector;

# Confirm PXF cluster health (PXF image)
docker exec greenplum-sne-pxf sudo -u gpadmin bash -lc \
  "source /usr/local/greenplum-db/greenplum_path.sh && \
   export PXF_HOME=/usr/local/pxf-gp7 && \
   export PXF_BASE=/home/gpadmin/pxf && \
   export JAVA_HOME=/usr/lib/jvm/java-11-openjdk && \
   export PATH=\$PXF_HOME/bin:\$PATH && \
   pxf cluster status"
```

> 🧪 <strong>Sample ML workflow:</strong> Open <code>MADLIB-EXTENSION.md</code> for full SQL + PL/Python3U demos including regression, clustering, and pandas/scikit-learn integrations.

---

## 🛠️ How It Works

1. <span style="font-family:'JetBrains Mono',monospace;color:#3CB371;">Dockerfile bootstrap</span> → installs Rocky Linux dependencies, Python 3.11, Java 11, SSH, compilers.
2. <span style="font-family:'Playfair Display',serif;color:#1E90FF;">`install-greenplum.sh`</span> → configures hostnames, sets `gpadmin`, initializes Greenplum, enables external access.
3. <span style="font-family:'Fira Code',monospace;color:#FF8A00;">Commit & tag</span> → the running container is committed to `greenplum-db:7.5.4`; add the alias with `docker tag greenplum-db:7.5.4 greenplum-sne-base:latest`.
4. <span style="font-family:'Lora',serif;color:#7B61FF;">PXF layer</span> → `extensions/pxf/Dockerfile` installs the RPM, seeds configs, and swaps in `startup-pxf.sh` for automatic service start.
5. <span style="font-family:'Source Code Pro',monospace;color:#FF5D8F;">Full analytics layer</span> → `extensions/madlib/Dockerfile` unpacks MADlib, ensures pgvector is active, and adds Python data science wheels.

📦 <strong>Composability:</strong>
```
greenplum-sne-full:latest
└── MADlib 2.2.0 + PyData stack
    └── greenplum-sne-pxf:latest
        └── PXF runtime & REST service
            └── greenplum-sne-base:latest (Greenplum 7.5.4 + pgvector)
```

---

## 🗺️ Project Atlas

| Path | What Lives Here |
| --- | --- |
| `container/Dockerfile` | Base build instructions & runtime bootstrap.
| `scripts/install-greenplum.sh` | Automated install + cluster init logging (<code>/tmp/greenplum-install.log</code>).
| `extensions/pxf/` | Dockerfile + install/start scripts for PXF 7.0.0.
| `extensions/madlib/` | Dockerfile + install/start scripts for MADlib & PyData stack.
| `IMAGE-LAYERS.md` | Deep dive sizing + retention recommendations.
| `PXF-EXTENSION.md` | Usage, configuration, and troubleshooting for external data.
| `MADLIB-EXTENSION.md` | End-to-end analytics cookbook with SQL/PL/Python recipes.
| `BASE-IMAGE-INFO.md` | Snapshot of the vanilla image and extension entry points.

---

## 🛟 Troubleshooting
- 🔍 **Install logs**: `docker logs greenplum-build-temp` during builds, plus `/tmp/greenplum-install.log` inside the container.
- ⏱️ **Install timeout**: `build-container.sh` polls for up to 10 minutes—check for RPM mismatches or disk pressure if it fails.
- 🔐 **Connection refused**: ensure Docker Desktop VMM is enabled and port `15432` isn't in use.
- 🌐 **PXF hiccups**: verify Java via `docker exec greenplum-sne-pxf java -version` and re-sync configs with `pxf cluster sync` (see `PXF-EXTENSION.md`).
- 🧠 **MADlib missing**: `DROP EXTENSION IF EXISTS madlib CASCADE; CREATE EXTENSION madlib CASCADE;` to refresh metadata.

---

## 🔗 Resources
- <a href="https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-greenplum/7/greenplum-database/install_guide-install_gpdb.html">Greenplum Installation Guide</a>
- <a href="https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-greenplum-platform-extension-framework/6-6/gp-pxf/overview_pxf.html">PXF Documentation</a>
- <a href="https://madlib.apache.org/docs/latest/index.html">MADlib Reference</a>
- <a href="https://github.com/pgvector/pgvector">pgvector GitHub</a>

---

## 📄 License
This project ships the automation and container scaffolding <em>as-is</em>. The included Greenplum Database, PXF, and MADlib artifacts remain subject to their respective VMware Tanzu and Apache licenses—review and comply with all vendor terms before redistribution.
