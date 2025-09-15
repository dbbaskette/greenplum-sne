# Full Analytics Extension for Greenplum SNE

## Overview

This extension brings comprehensive analytics capabilities to Greenplum SNE, including:
- **MADlib**: In-database machine learning and statistics
- **pgvector**: Vector similarity search and embeddings
- **PXF**: External data source connectivity

Together, these provide a complete platform for modern data analytics, ML/AI workloads, and vector-based applications.

## Features

MADlib 2.2.0 includes:

### Machine Learning Algorithms
- **Supervised Learning**: Linear & Logistic Regression, SVM, Decision Trees, Random Forests, Neural Networks
- **Unsupervised Learning**: K-Means, DBSCAN Clustering, PCA, Association Rules
- **Deep Learning**: Keras-based Deep Learning with TensorFlow backend
- **Time Series Analysis**: ARIMA models

### Statistical Methods
- Descriptive Statistics
- Hypothesis Testing
- Probability Functions
- Sampling Methods

### Graph Analytics
- PageRank
- Shortest Path
- Connected Components
- Graph Measures

## pgvector 0.7.0 Features

### Vector Operations
- **Vector Data Type**: Store high-dimensional vectors (up to 16,000 dimensions)
- **Distance Functions**: L2, cosine, inner product, L1 distances
- **Indexing**: IVFFlat and HNSW indexes for fast similarity search
- **Embeddings Support**: Perfect for AI/ML applications with sentence transformers, OpenAI embeddings, etc.

## Quick Start

### Building the Full Extensions Container

The MADlib extension is built on top of the PXF-enabled container:

```bash
# Build everything (base + PXF + MADlib)
./build-full-extensions.sh
```

### Running the Container

```bash
docker run -d \
  -p 15432:5432 \
  --hostname greenplum-sne \
  --name greenplum-sne-full \
  greenplum-sne-full:latest
```

### Connecting to the Database

```bash
psql -h localhost -p 15432 -U gpadmin -d postgres
# Password: VMware1!
```

## Using MADlib

### Enable MADlib Extension

The extension is automatically created when the container starts, but you can manually create it:

```sql
CREATE EXTENSION IF NOT EXISTS madlib CASCADE;
```

### Verify Installation

```sql
-- Check MADlib version
SELECT madlib.version();

-- List all MADlib functions (there are hundreds!)
SELECT * FROM madlib.summary();
```

## Example Usage

### 1. Linear Regression

```sql
-- Create sample data
DROP TABLE IF EXISTS houses;
CREATE TABLE houses (
    id SERIAL,
    size INTEGER,
    bedrooms INTEGER,
    price INTEGER
) DISTRIBUTED BY (id);

INSERT INTO houses (size, bedrooms, price) VALUES
    (1500, 3, 300000),
    (2000, 4, 400000),
    (1200, 2, 250000),
    (1800, 3, 350000),
    (2500, 4, 500000),
    (1000, 2, 200000),
    (1700, 3, 320000),
    (2200, 4, 450000);

-- Train linear regression model
DROP TABLE IF EXISTS house_model, house_model_summary;
SELECT madlib.linregr_train(
    'houses',           -- source table
    'house_model',      -- output model table
    'price',            -- dependent variable
    'ARRAY[1, size, bedrooms]'  -- independent variables
);

-- View model coefficients
SELECT * FROM house_model;

-- Make predictions
SELECT 
    size,
    bedrooms,
    price as actual_price,
    madlib.linregr_predict(
        coef, 
        ARRAY[1, size, bedrooms]::FLOAT8[]
    ) as predicted_price
FROM houses, house_model;
```

### 2. K-Means Clustering

```sql
-- Create sample data
DROP TABLE IF EXISTS points;
CREATE TABLE points (
    id SERIAL,
    coordinates FLOAT8[]
) DISTRIBUTED BY (id);

INSERT INTO points (coordinates) VALUES
    (ARRAY[1.0, 1.0]),
    (ARRAY[1.5, 2.0]),
    (ARRAY[3.0, 4.0]),
    (ARRAY[5.0, 7.0]),
    (ARRAY[3.5, 5.0]),
    (ARRAY[4.5, 5.0]),
    (ARRAY[3.5, 4.5]);

-- Perform K-means clustering
DROP TABLE IF EXISTS kmeans_result;
SELECT madlib.kmeans(
    'points',           -- source table
    'coordinates',      -- column with data points
    2,                  -- number of clusters
    'madlib.squared_dist_norm2',  -- distance function
    'madlib.avg',       -- aggregate function
    20,                 -- max iterations
    0.001              -- convergence threshold
);
```

### 3. Decision Trees

```sql
-- Create sample data for classification
DROP TABLE IF EXISTS patients;
CREATE TABLE patients (
    id SERIAL,
    age INTEGER,
    blood_pressure INTEGER,
    cholesterol INTEGER,
    has_disease BOOLEAN
) DISTRIBUTED BY (id);

INSERT INTO patients (age, blood_pressure, cholesterol, has_disease) VALUES
    (25, 120, 180, false),
    (35, 130, 200, false),
    (45, 140, 240, true),
    (55, 150, 260, true),
    (65, 160, 280, true),
    (30, 125, 190, false),
    (50, 145, 250, true),
    (40, 135, 220, false);

-- Train decision tree
DROP TABLE IF EXISTS dt_model, dt_model_summary;
SELECT madlib.tree_train(
    'patients',                     -- source table
    'dt_model',                     -- output model table
    'id',                           -- id column
    'has_disease',                  -- response
    'age, blood_pressure, cholesterol',  -- features
    NULL,                           -- exclude columns
    'gini',                         -- split criterion
    NULL,                           -- grouping columns
    NULL,                           -- weights
    10,                             -- max depth
    2,                              -- min split
    1,                              -- min bucket
    3                               -- number of bins
);

-- Display the tree
SELECT madlib.tree_display('dt_model');
```

### 4. Principal Component Analysis (PCA)

```sql
-- Create sample data
DROP TABLE IF EXISTS features_data;
CREATE TABLE features_data (
    id SERIAL,
    features FLOAT8[]
) DISTRIBUTED BY (id);

-- Insert sample high-dimensional data
INSERT INTO features_data (features)
SELECT ARRAY[random(), random(), random(), random(), random()]
FROM generate_series(1, 100);

-- Perform PCA
DROP TABLE IF EXISTS pca_result, pca_result_mean;
SELECT madlib.pca_train(
    'features_data',    -- source table
    'pca_result',       -- output table
    'id',               -- row id column
    'features',         -- feature column
    NULL,               -- number of principal components (NULL = all)
    NULL,               -- grouping columns
    NULL,               -- number of iterations
    NULL,               -- convergence tolerance
    FALSE,              -- use correlation matrix
    FALSE               -- use SVD
);

-- View principal components
SELECT * FROM pca_result;
```

### 5. Vector Similarity Search with pgvector

```sql
-- Create a table for document embeddings
DROP TABLE IF EXISTS documents;
CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    title TEXT,
    content TEXT,
    embedding vector(1536)  -- OpenAI embedding dimension
) DISTRIBUTED BY (id);

-- Insert sample documents with mock embeddings
INSERT INTO documents (title, content, embedding) VALUES
    ('AI Research', 'Latest developments in artificial intelligence', 
     array_fill(random(), ARRAY[1536])::vector),
    ('Database Systems', 'Modern database architecture and design',
     array_fill(random(), ARRAY[1536])::vector),
    ('Machine Learning', 'Supervised and unsupervised learning methods',
     array_fill(random(), ARRAY[1536])::vector),
    ('Vector Databases', 'Similarity search and vector operations',
     array_fill(random(), ARRAY[1536])::vector);

-- Find similar documents using cosine similarity
WITH query_vector AS (
    SELECT embedding FROM documents WHERE title = 'AI Research'
)
SELECT d.title, d.content,
       d.embedding <=> q.embedding as cosine_distance
FROM documents d, query_vector q
WHERE d.title != 'AI Research'
ORDER BY d.embedding <=> q.embedding
LIMIT 3;

-- Create an index for faster similarity search
CREATE INDEX ON documents USING ivfflat (embedding vector_cosine_ops) 
WITH (lists = 100);

-- Alternatively, use HNSW index (more accurate but slower to build)
-- CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops);
```

## Architecture

The Full Analytics extension for Greenplum SNE:

1. **Built on PXF Container**: Extends `greenplum-sne-pxf:latest`
2. **Components**:
   - MADlib 2.2.0 libraries and modules  
   - pgvector 0.7.0 (built-in with Greenplum)
   - PXF 7.0.0 platform extension framework
   - Python integration for advanced algorithms
   - SQL extension files for all components
3. **Installation Process**:
   - MADlib: Extracts gppkg archive and installs libraries/extensions
   - pgvector: Auto-enabled (pre-installed with Greenplum 7.5.4)
   - PXF: Cluster initialization and service startup
   - All extensions automatically created at container startup

## Container Stack

```
greenplum-sne-full:latest
    ├── MADlib 2.2.0 (Machine Learning)
    └── greenplum-sne-pxf:latest
            ├── PXF 7.0.0 (External Data)
            └── greenplum-sne-base:latest
                    ├── pgvector 0.7.0 (Vector Search)
                    └── Greenplum 7.5.4 (Database + Python3)
```

## Performance Considerations

- MADlib operations are distributed across Greenplum segments
- Large datasets benefit from Greenplum's MPP architecture
- Some algorithms support GPU acceleration (if available)
- Memory-intensive operations may require tuning `statement_mem`

## Troubleshooting

### MADlib Functions Not Found

If MADlib functions are not available:

```sql
-- Recreate the extension
DROP EXTENSION IF EXISTS madlib CASCADE;
CREATE EXTENSION madlib CASCADE;

-- Verify installation
SELECT madlib.version();
```

### Memory Errors

For large datasets, increase memory:

```sql
-- Increase statement memory for current session
SET statement_mem = '2GB';

-- For persistent changes, modify postgresql.conf
```

### Python Dependencies

MADlib uses Python for some algorithms. The container includes Python 3.11 with required packages.

## Resources

### MADlib
- [MADlib Documentation](https://madlib.apache.org/docs/latest/index.html)
- [MADlib GitHub Repository](https://github.com/apache/madlib)
- [Greenplum MADlib Guide](https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-greenplum/7/greenplum-database/analytics-madlib.html)

### pgvector
- [pgvector Documentation](https://github.com/pgvector/pgvector)
- [pgvector Performance Guide](https://github.com/pgvector/pgvector#performance)
- [Vector Similarity Search Examples](https://github.com/pgvector/pgvector#examples)

## Image Details

- **Full Image**: `greenplum-sne-full:7.5.4-pxf7.0.0-madlib2.2.0`
- **Size**: ~4.5GB
- **Includes**: 
  - Greenplum 7.5.4 with Python 3.11
  - PXF 7.0.0 (Platform Extension Framework)
  - MADlib 2.2.0 (Machine Learning Library) 
  - pgvector 0.7.0 (Vector Similarity Search)
- **Base OS**: Rocky Linux 9