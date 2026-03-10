#!/bin/bash

# Required per rubric: scripts/backup.sh
source .env

DB_FILE=./data/primary/application.db
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE=backup-$TIMESTAMP.sql.gz

gzip -c $DB_FILE > $BACKUP_FILE

aws --endpoint-url=http://localhost:4566 s3 cp $BACKUP_FILE s3://$PRIMARY_BUCKET_NAME/