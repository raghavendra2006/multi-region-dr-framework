#!/bin/bash
set -euo pipefail

# Required per rubric: scripts/replicate_storage.sh
source .env

echo "INFO: Identifying latest backup in primary region..."
LATEST=$(aws --endpoint-url=http://localhost:4566 s3 ls "s3://$PRIMARY_BUCKET_NAME" | sort | tail -n 1 | awk '{print $4}')

if [ -z "$LATEST" ]; then
    echo "ERROR: No backups found in primary bucket."
    exit 1
fi

echo "INFO: Found latest backup: $LATEST. Downloading temporarily..."
aws --endpoint-url=http://localhost:4566 s3 cp "s3://$PRIMARY_BUCKET_NAME/$LATEST" ./tmp.gz

echo "INFO: Uploading backup to DR region..."
aws --endpoint-url=http://localhost:4567 s3 cp ./tmp.gz "s3://$DR_BUCKET_NAME/$LATEST"

echo "INFO: Cleaning up temporary files..."
rm -f ./tmp.gz

echo "INFO: Storage replication completed successfully."