#!/bin/bash
set -euo pipefail

# ---------------------------------------------------------------
# scripts/replicate_storage.sh
# Lists objects in the primary S3 bucket, identifies the most
# recent backup, and copies it to the DR S3 bucket.
# ---------------------------------------------------------------

# Source environment variables for bucket names
source .env

echo "INFO: Listing objects in primary bucket to identify latest backup..."
LATEST=$(aws --endpoint-url=http://localhost:4566 s3 ls "s3://${PRIMARY_BUCKET_NAME}/" | sort | tail -n 1 | awk '{print $4}')

if [ -z "$LATEST" ]; then
    echo "ERROR: No backups found in primary bucket s3://$PRIMARY_BUCKET_NAME/."
    exit 1
fi

echo "INFO: Latest backup identified: $LATEST"

# Download the latest backup from primary region
echo "INFO: Downloading $LATEST from primary region..."
aws --endpoint-url=http://localhost:4566 s3 cp "s3://${PRIMARY_BUCKET_NAME}/${LATEST}" "./tmp_replicate.gz"

# Upload the backup to DR region bucket
echo "INFO: Uploading $LATEST to DR region bucket s3://$DR_BUCKET_NAME/..."
aws --endpoint-url=http://localhost:4567 s3 cp "./tmp_replicate.gz" "s3://${DR_BUCKET_NAME}/${LATEST}"

# Cleanup temporary file
echo "INFO: Cleaning up temporary files..."
rm -f "./tmp_replicate.gz"

echo "INFO: Storage replication completed successfully."
echo "INFO: $LATEST is now available in s3://$DR_BUCKET_NAME/"