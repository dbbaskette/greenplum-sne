#!/bin/bash

# Greenplum Container Test Script
# Tests the built container to ensure Greenplum is working correctly

set -e

# Configuration
IMAGE_NAME="greenplum-db:7.5.4"
CONTAINER_NAME="greenplum-test"
TEST_TIMEOUT=300  # 5 minutes

echo "=== Greenplum Container Test ==="
echo "Testing image: $IMAGE_NAME"
echo "Timestamp: $(date)"
echo ""

# Clean up any existing test container
echo "Cleaning up previous test container..."
docker stop "$CONTAINER_NAME" 2>/dev/null || true
docker rm "$CONTAINER_NAME" 2>/dev/null || true

# Start test container
echo "Starting test container..."
docker run -d \
    --platform linux/amd64 \
    --hostname greenplum-sne \
    --name "$CONTAINER_NAME" \
    -p 15432:5432 \
    "$IMAGE_NAME"

echo "Container started. Waiting for Greenplum to be ready..."
echo "This may take 2-3 minutes for installation and startup..."

# Wait for Greenplum to be ready
attempt=1
max_attempts=$((TEST_TIMEOUT / 10))

while [ $attempt -le $max_attempts ]; do
    if psql -h localhost -p 15432 -U gpadmin -d postgres -c "SELECT 'Database ready!' as status;" > /dev/null 2>&1; then
        echo ""
        echo "✅ Greenplum is ready!"
        break
    fi
    
    # Show progress every minute
    if [ $((attempt % 6)) -eq 0 ]; then
        minutes=$((attempt / 6))
        echo "Still waiting... ${minutes} minute(s) elapsed"
    else
        echo -n "."
    fi
    
    sleep 10
    ((attempt++))
done

if [ $attempt -gt $max_attempts ]; then
    echo ""
    echo "❌ Greenplum did not start within expected time"
    echo "Container logs:"
    docker logs "$CONTAINER_NAME" | tail -20
    exit 1
fi

# Run database tests
echo ""
echo "=== Running Database Tests ==="

# Test 1: Basic connection and version
echo "Test 1: Database version..."
VERSION_OUTPUT=$(psql -h localhost -p 15432 -U gpadmin -d postgres -t -c "SELECT version();" 2>/dev/null)
if echo "$VERSION_OUTPUT" | grep -q "Greenplum"; then
    echo "✅ Database version check passed"
    echo "   $VERSION_OUTPUT" | xargs
else
    echo "❌ Database version check failed"
    exit 1
fi

# Test 2: Create table and insert data
echo "Test 2: Create table and insert data..."
psql -h localhost -p 15432 -U gpadmin -d postgres << 'SQL_TEST' > /dev/null 2>&1
DROP TABLE IF EXISTS test_table;
CREATE TABLE test_table (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    value INTEGER
) DISTRIBUTED BY (id);

INSERT INTO test_table (name, value) VALUES
    ('test1', 100),
    ('test2', 200),
    ('test3', 300);
SQL_TEST

if [ $? -eq 0 ]; then
    echo "✅ Table creation and data insertion passed"
else
    echo "❌ Table creation and data insertion failed"
    exit 1
fi

# Test 3: Query data
echo "Test 3: Query data..."
ROW_COUNT=$(psql -h localhost -p 15432 -U gpadmin -d postgres -t -c "SELECT COUNT(*) FROM test_table;" 2>/dev/null | xargs)
if [ "$ROW_COUNT" = "3" ]; then
    echo "✅ Data query test passed (found $ROW_COUNT rows)"
else
    echo "❌ Data query test failed (expected 3 rows, found $ROW_COUNT)"
    exit 1
fi

# Test 4: Check cluster status
echo "Test 4: Cluster status..."
CLUSTER_STATUS=$(docker exec "$CONTAINER_NAME" sudo -u gpadmin bash -c "source /usr/local/greenplum-db/greenplum_path.sh && gpstate -s" 2>/dev/null)
if echo "$CLUSTER_STATUS" | grep -q "segments are acting as primaries"; then
    echo "✅ Cluster status check passed"
else
    echo "❌ Cluster status check failed"
    exit 1
fi

# Clean up test data
echo "Cleaning up test data..."
psql -h localhost -p 15432 -U gpadmin -d postgres -c "DROP TABLE test_table;" > /dev/null 2>&1

echo ""
echo "=== Test Summary ==="
echo "✅ All tests passed!"
echo "✅ Container: $CONTAINER_NAME"
echo "✅ Database accessible at: localhost:15432"
echo "✅ Username: gpadmin"
echo "✅ Password: VMware1!"
echo ""
echo "Container is ready for use!"
echo ""
echo "To connect manually:"
echo "  psql -h localhost -p 15432 -U gpadmin -d postgres"
echo ""
echo "To stop and remove test container:"
echo "  docker stop $CONTAINER_NAME && docker rm $CONTAINER_NAME"