#!/bin/bash

source .env.example

DB_FILE=./data/primary/application.db
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE=backup-$TIMESTAMP.db.gz

gzip -c $DB_FILE > $BACKUP_FILE

aws --endpoint-url=http://localhost:4566 s3 cp $BACKUP_FILE s3://$PRIMARY_BUCKET_NAME/