#!/bin/bash
set -euo pipefail

# ---------------------------------------------------------------
# scripts/init-dr.sh
# Auto-provisions the DR S3 bucket on LocalStack startup.
# Bucket name and region are sourced from environment variables
# passed via docker-compose.yml.
# ---------------------------------------------------------------

BUCKET="${DR_BUCKET_NAME:-my-app-backups-dr}"
REGION="${DR_REGION:-us-west-2}"

echo "INFO: Auto-Provisioning DR S3 Bucket: ${BUCKET} in ${REGION}..."
awslocal s3 mb "s3://${BUCKET}" --region "${REGION}"
echo "INFO: DR S3 Bucket [${BUCKET}] Ready."
