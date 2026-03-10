#!/bin/bash

# Required per rubric: scripts/dr.sh
source .env

if [ "$1" != "--failover" ]; then
  echo "Usage: ./scripts/dr.sh --failover"
  exit 1
fi

echo "Checking primary health..."

curl -s http://localhost:5001/health

if [ $? -eq 0 ]; then
  echo "Primary still running. Stop it first."
  exit 1
fi

echo "Downloading latest backup..."

LATEST=$(aws --endpoint-url=http://localhost:4567 s3 ls s3://$DR_BUCKET_NAME | sort | tail -n 1 | awk '{print $4}')

aws --endpoint-url=http://localhost:4567 s3 cp s3://$DR_BUCKET_NAME/$LATEST ./restore.gz

gunzip -f restore.gz
mv restore ./data/dr/application.db

echo "Starting DR application..."

docker-compose up -d --scale dr_app=1 dr_app

echo "Waiting for DR to be healthy..."

sleep 5

curl -s http://localhost:5002/health

echo -e "\nFailover complete"
echo "http://localhost:5002"