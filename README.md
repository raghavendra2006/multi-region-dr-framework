# Multi-Region Disaster Recovery Framework

This repository contains a proof-of-concept framework for testing active-passive Disaster Recovery (DR) strategies. It simulates a primary and a DR region using Docker and LocalStack (AWS S3 mock).

## Architecture

- **Primary Environment:** A Flask application backed by SQLite, running on port `5001`. Backups are stored in a simulated S3 bucket (`primary-backups`) via LocalStack (port `4566`).
- **DR Environment:** A standby Flask application running on port `5002`. During failover, it restores data from the simulated DR S3 bucket (`dr-backups`) via LocalStack (port `4567`).
- **Storage Replication:** Database backups are copied cross-region from the primary S3 bucket to the DR S3 bucket to ensure data availability in the event of a primary region outage.
- **Compute Replication:** The application's Docker image is built and pushed to a remote registry (Docker Hub) to ensure the compute artifacts can be quickly provisioned in the DR region.

## Prerequisites

- Docker Desktop / Docker Engine
- Docker Compose
- AWS CLI
- Python (for manual script translation if needed on Windows)
- Bash or PowerShell

## Setup Configuration

1. Copy the example environment variables file:
   ```bash
   cp .env.example .env
   ```
2. Initialize the Infrastructure & Create the S3 Buckets:
   Run the following commands to start LocalStack and create the mock AWS S3 buckets required for backups:
   ```bash
   docker-compose up -d primary_localstack dr_localstack
   
   # Wait a few seconds for LocalStack to boot, then run:
   aws --endpoint-url=http://localhost:4566 s3 mb s3://primary-backups
   aws --endpoint-url=http://localhost:4567 s3 mb s3://dr-backups
   ```

## Execution & Usage

### 1. Starting the Primary Infrastructure
Bring up the LocalStack infrastructure and the active Primary Application:
```bash
docker-compose up -d primary_localstack dr_localstack primary_app
```

### 2. Compute Replication
Build the application image and push it to Docker Hub for DR availability:
```bash
bash ./scripts/replicate_compute.sh
```
*(Note: Requires `docker login` prior to execution. Currently tagged for Docker Hub user `raghavendra76`.)*

### 3. Failover Testing Workflow
You can simulate a full disaster recovery scenario with the provided scripts or manual terminal commands:

1. **Generate Mock Data:** 
   ```bash
   curl -X POST http://localhost:5001/write
   ```
2. **Execute Primary Backup:** 
   Zip the `./data/primary/application.db` file and upload it to the `primary-backups` S3 bucket.
3. **Replicate Storage:** 
   Copy the newest `.gz` snapshot from the `primary-backups` S3 bucket to the `dr-backups` S3 bucket.
4. **Simulate Catastrophic Outage:** 
   ```bash
   docker-compose stop primary_app
   ```
5. **Execute DR Runbook:** 
   Download the snapshot from the DR bucket, uncompress it to `./data/dr/application.db`, and start the DR environment:
   ```bash
   docker-compose up -d dr_app
   ```
6. **Verify Restored Data:** 
   ```bash
   curl http://localhost:5002/data
   ```

## Metrics
See `DR_METRICS.md` for target Recovery Time Objectives (RTO) and Recovery Point Objectives (RPO).