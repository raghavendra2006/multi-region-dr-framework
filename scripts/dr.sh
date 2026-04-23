#!/bin/bash
set -euo pipefail

# ---------------------------------------------------------------
# scripts/dr.sh
# Central DR orchestration script. Validates --failover argument,
# checks primary health, downloads latest backup from DR bucket,
# restores the database, and starts the dr_app service.
# ---------------------------------------------------------------

# Source environment variables for bucket names and paths
source .env

# -----------------------------------------------------------
# Step 0: Parse and validate the --failover argument
# -----------------------------------------------------------
if [ "${1:-}" != "--failover" ]; then
    echo "Usage: ./scripts/dr.sh --failover"
    echo "  --failover   Initiate disaster recovery failover"
    exit 1
fi

echo "=========================================="
echo "  DISASTER RECOVERY FAILOVER INITIATED"
echo "=========================================="

# -----------------------------------------------------------
# Step 1: Health check on primary service
# -----------------------------------------------------------
echo ""
echo "INFO: Checking primary service health at http://localhost:5001/health..."

if curl -s -f http://localhost:5001/health > /dev/null 2>&1; then
    echo "WARNING: Primary service is still responding. Failover aborted."
    echo "INFO: Stop the primary service first before initiating failover."
    exit 1
fi

echo "INFO: Primary service is DOWN. Proceeding with failover..."

# -----------------------------------------------------------
# Step 2: Download latest backup from DR S3 bucket
# -----------------------------------------------------------
echo ""
echo "INFO: Listing backups in DR bucket s3://$DR_BUCKET_NAME/..."
LATEST=$(aws --endpoint-url=http://localhost:4567 s3 ls "s3://${DR_BUCKET_NAME}/" | sort | tail -n 1 | awk '{print $4}')

if [ -z "$LATEST" ]; then
    echo "ERROR: No backups found in DR bucket. Cannot restore."
    exit 1
fi

echo "INFO: Latest backup found: $LATEST"
echo "INFO: Downloading $LATEST from DR bucket..."
aws --endpoint-url=http://localhost:4567 s3 cp "s3://${DR_BUCKET_NAME}/${LATEST}" "./restore_backup.sql.gz"

# -----------------------------------------------------------
# Step 3: Restore the database from the downloaded backup
# -----------------------------------------------------------
echo ""
echo "INFO: Decompressing backup..."
gunzip -f "./restore_backup.sql.gz"

# Ensure the DR data directory exists
mkdir -p ./data/dr

echo "INFO: Restoring database to ./data/dr/application.db..."
sqlite3 ./data/dr/application.db < "./restore_backup.sql"

# Cleanup
rm -f "./restore_backup.sql"

echo "INFO: Database restored successfully."

# -----------------------------------------------------------
# Step 4: Start the dr_app service via docker-compose
# -----------------------------------------------------------
echo ""
echo "INFO: Starting dr_app service..."
docker-compose up -d --scale dr_app=1 dr_app

echo "INFO: Waiting for DR application to become healthy..."
sleep 8

# Verify DR app is responding
if curl -s -f http://localhost:5002/health > /dev/null 2>&1; then
    echo ""
    echo "=========================================="
    echo "  FAILOVER COMPLETED SUCCESSFULLY"
    echo "=========================================="
    echo "  DR Application: http://localhost:5002"
    echo "  Data endpoint:  http://localhost:5002/data"
    echo "=========================================="
else
    echo "ERROR: DR application failed to start. Check logs with: docker-compose logs dr_app"
    exit 1
fi