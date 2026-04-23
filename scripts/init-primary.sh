#!/bin/bash
set -euo pipefail
echo "INFO: Auto-Provisioning Primary S3 Bucket..."
awslocal s3 mb s3://my-app-backups-primary --region us-east-1
echo "INFO: Primary S3 Bucket Ready."
