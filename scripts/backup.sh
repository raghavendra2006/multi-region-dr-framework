#!/bin/bash
set -euo pipefail

# ---------------------------------------------------------------
# scripts/backup.sh
# Performs a SQLite database dump, compresses it, and uploads
# the timestamped backup to the primary S3 bucket (LocalStack).
# ---------------------------------------------------------------

# Source environment variables for bucket names and paths
source .env

DB_FILE="${PRIMARY_DB_PATH:-./data/primary/application.db}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
DUMP_FILE="backup-${TIMESTAMP}.sql"
BACKUP_FILE="backup-${TIMESTAMP}.sql.gz"

# Cleanup handler — remove temp files on failure
cleanup() {
    echo "WARN: Cleaning up temporary files after failure..."
    rm -f "$DUMP_FILE" "$BACKUP_FILE"
}
trap cleanup ERR

echo "INFO: Starting primary database backup process..."
echo "INFO: Timestamp: ${TIMESTAMP}"

# Validate that the database file exists
if [ ! -f "$DB_FILE" ]; then
    echo "ERROR: Database file $DB_FILE not found."
    exit 1
fi

# Step 1: Perform a SQLite database dump to SQL text
echo "INFO: Dumping database to $DUMP_FILE..."
sqlite3 "$DB_FILE" .dump > "$DUMP_FILE"
echo "INFO: Database dump complete. Size: $(wc -c < "$DUMP_FILE") bytes"

# Step 2: Compress the dump file with gzip
echo "INFO: Compressing dump into $BACKUP_FILE..."
gzip -f "$DUMP_FILE"
echo "INFO: Compressed backup size: $(wc -c < "$BACKUP_FILE") bytes"

# Step 3: Upload compressed backup to primary S3 bucket with timestamp
echo "INFO: Uploading $BACKUP_FILE to s3://${PRIMARY_BUCKET_NAME}/..."
aws --endpoint-url=http://localhost:4566 s3 cp "$BACKUP_FILE" "s3://${PRIMARY_BUCKET_NAME}/${BACKUP_FILE}"

# Cleanup local backup file after successful upload
rm -f "$BACKUP_FILE"

echo "INFO: Backup completed successfully."
echo "INFO: Object: s3://${PRIMARY_BUCKET_NAME}/${BACKUP_FILE}"