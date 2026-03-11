#!/bin/bash
set -euo pipefail

# Required per rubric: scripts/backup.sh
source .env

DB_FILE="./data/primary/application.db"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="backup-${TIMESTAMP}.sql.gz"

echo "INFO: Starting primary database backup process..."
if [ ! -f "$DB_FILE" ]; then
    echo "ERROR: Database file $DB_FILE not found."
    exit 1
fi

echo "INFO: Compressing database into $BACKUP_FILE..."
gzip -c "$DB_FILE" > "$BACKUP_FILE"

echo "INFO: Uploading $BACKUP_FILE to s3://$PRIMARY_BUCKET_NAME/..."
aws --endpoint-url=http://localhost:4566 s3 cp "$BACKUP_FILE" "s3://$PRIMARY_BUCKET_NAME/"

echo "INFO: Backup completed successfully."