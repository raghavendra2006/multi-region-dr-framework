#!/bin/bash

source .env.example

LATEST=$(aws --endpoint-url=http://localhost:4566 s3 ls s3://$PRIMARY_BUCKET_NAME | sort | tail -n 1 | awk '{print $4}')

aws --endpoint-url=http://localhost:4566 s3 cp s3://$PRIMARY_BUCKET_NAME/$LATEST ./tmp.gz

aws --endpoint-url=http://localhost:4567 s3 cp ./tmp.gz s3://$DR_BUCKET_NAME/$LATEST