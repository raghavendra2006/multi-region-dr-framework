#!/bin/bash

source .env.example

if [ "$1" != "--failover" ]; then
  echo "Usage: ./dr.sh --failover"
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

gunzip restore.gz
mv restore ./data/dr/application.db

echo "Starting DR application..."

docker-compose up -d dr_app

echo "Waiting for DR to be healthy..."

sleep 10

curl http://localhost:5002/health

echo "Failover complete"
echo "Active Endpoint: http://localhost:5002"