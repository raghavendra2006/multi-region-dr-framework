#!/bin/bash
set -euo pipefail
echo "INFO: Auto-Provisioning DR S3 Bucket..."
awslocal s3 mb s3://my-app-backups-dr --region us-west-2
echo "INFO: DR S3 Bucket Ready."
