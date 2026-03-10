#!/bin/bash

# Build the application image
echo "Building the primary_app image..."
docker build -t multi-region-dr-framework-app ./app

# Tag the image with the Docker Hub repository
echo "Tagging the image..."
docker tag multi-region-dr-framework-app raghavendra76/multi-region-dr-framework:latest

# Push the image to Docker Hub
echo "Pushing the image to Docker Hub..."
docker push raghavendra76/multi-region-dr-framework:latest

echo "Compute replication script completed."
