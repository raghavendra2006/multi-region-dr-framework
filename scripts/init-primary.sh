#!/bin/bash
set -euo pipefail

# ---------------------------------------------------------------
# scripts/init-primary.sh
# Auto-provisions the primary S3 bucket on LocalStack startup.
# Bucket name and region are sourced from environment variables
# passed via docker-compose.yml.
# ---------------------------------------------------------------

BUCKET="${PRIMARY_BUCKET_NAME:-my-app-backups-primary}"
REGION="${PRIMARY_REGION:-us-east-1}"

echo "INFO: Auto-Provisioning Primary S3 Bucket: ${BUCKET} in ${REGION}..."
awslocal s3 mb "s3://${BUCKET}" --region "${REGION}"
echo "INFO: Primary S3 Bucket [${BUCKET}] Ready."
