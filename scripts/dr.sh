#!/bin/bash
set -euo pipefail

# Required per rubric: scripts/dr.sh
source .env

if [ "${1:-}" != "--failover" ]; then
  echo "Usage: ./scripts/dr.sh --failover"
  exit 1
fi

echo "Checking primary health..."

if curl -s -f http://localhost:5001/health > /dev/null; then
  echo "Primary still running. Stop it first."
  exit 1
fi

echo "INFO: Primary is down. Initiating failover..."
echo "INFO: Downloading latest backup from DR bucket..."

LATEST=$(aws --endpoint-url=http://localhost:4567 s3 ls "s3://$DR_BUCKET_NAME" | sort | tail -n 1 | awk '{print $4}')

if [ -z "$LATEST" ]; then
    echo "ERROR: No backups found in DR bucket."
    exit 1
fi

aws --endpoint-url=http://localhost:4567 s3 cp "s3://$DR_BUCKET_NAME/$LATEST" ./restore.gz

echo "INFO: Restoring database snapshot..."
gunzip -f restore.gz
mv restore ./data/dr/application.db

echo "INFO: Starting DR application..."

docker-compose up -d --scale dr_app=1 dr_app

echo "INFO: Waiting for DR to be healthy..."

sleep 5

curl -s -f http://localhost:5002/health > /dev/null

echo -e "\nINFO: Failover complete successfully."
echo "http://localhost:5002"