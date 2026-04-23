# Multi-Region Disaster Recovery Framework

This repository contains a production-grade, proof-of-concept framework for testing **active-passive Disaster Recovery (DR)** strategies. It simulates a primary and a DR region using Docker and LocalStack (AWS S3/EC2 mock).

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      HOST MACHINE                               │
│                                                                 │
│  ┌──────────────┐    backup.sh     ┌───────────────────┐        │
│  │ primary_app  │ ──────────────►  │ primary_localstack│        │
│  │  Flask:5001  │   sqlite3 dump   │  S3 Bucket :4566  │        │
│  │  SQLite DB   │   + gzip + s3cp  │                   │        │
│  └──────────────┘                  └────────┬──────────┘        │
│                                             │                   │
│                              replicate_storage.sh               │
│                                             │                   │
│  ┌──────────────┐    dr.sh         ┌────────▼──────────┐        │
│  │   dr_app     │ ◄──────────────  │  dr_localstack    │        │
│  │  Flask:5002  │  s3 download +   │  S3 Bucket :4567  │        │
│  │  (standby)   │  sqlite3 restore │                   │        │
│  └──────────────┘                  └───────────────────┘        │
└─────────────────────────────────────────────────────────────────┘
```

- **Primary Environment:** A Flask application backed by SQLite, running on port `5001`. Database backups (via `sqlite3 .dump`) are compressed and stored in a simulated S3 bucket (`my-app-backups-primary`) via LocalStack (port `4566`).
- **DR Environment:** A standby Flask application on port `5002`. During failover, it restores data from the DR S3 bucket (`my-app-backups-dr`) via LocalStack (port `4567`).
- **Storage Replication:** Backups are copied cross-region from the primary S3 bucket to the DR S3 bucket to ensure data availability during a primary region outage.
- **Infrastructure as Code:** Terraform definitions in `iac/main.tf` declare S3 buckets and EC2 instances for both regions using variables (no hardcoded credentials).

## Prerequisites

- Docker Desktop / Docker Engine
- Docker Compose
- AWS CLI (v2)
- SQLite3
- Bash shell

## Setup Configuration

1. **Copy the environment variables file:**
   ```bash
   cp .env.example .env
   ```

2. **Initialize the Infrastructure:**
   Start LocalStack and the primary application. S3 buckets are auto-provisioned on boot via init scripts.
   ```bash
   docker-compose up -d --build primary_app primary_localstack dr_localstack
   ```

## Execution & Usage

### 1. Starting the Primary Infrastructure

Bring up the LocalStack infrastructure and the active Primary Application:
```bash
docker-compose up -d --build primary_app primary_localstack dr_localstack
```

### 2. Compute Replication

Validate that the IaC definitions for the DR region are present:
```bash
bash ./scripts/replicate_compute.sh
```

### 3. Failover Testing Workflow (End-to-End)

Complete disaster recovery simulation:

**Step 1 — Generate Mock Data:**
```bash
curl -X POST http://localhost:5001/write
curl -X POST http://localhost:5001/write
curl http://localhost:5001/data   # Verify records exist
```

**Step 2 — Execute Primary Backup:**
Performs a `sqlite3 .dump`, compresses with `gzip`, and uploads to the primary S3 bucket with a timestamp.
```bash
bash ./scripts/backup.sh
```

**Step 3 — Replicate Storage to DR Region:**
Identifies the latest backup in the primary bucket and copies it to the DR bucket.
```bash
bash ./scripts/replicate_storage.sh
```

**Step 4 — Simulate Catastrophic Outage:**
```bash
docker-compose stop primary_app
```

**Step 5 — Execute DR Failover:**
Downloads the backup from the DR bucket, restores the database via `sqlite3`, and starts the `dr_app` container.
```bash
bash ./scripts/dr.sh --failover
```

**Step 6 — Verify Restored Data:**
```bash
curl http://localhost:5002/data   # Should show identical records
```

## Infrastructure as Code

The `iac/main.tf` file defines:
- **S3 Buckets** with versioning enabled for both primary and DR regions
- **EC2 Instances** (placeholder compute) for both regions
- **Variables** for regions, bucket names, and AMI IDs (no hardcoded credentials)
- **Outputs** for resource IDs

To validate (requires Terraform):
```bash
cd iac && terraform init && terraform validate
```

## Metrics

See [DR_METRICS.md](DR_METRICS.md) for detailed RTO/RPO analysis, bottleneck identification, and improvement recommendations.

## Project Structure

```
multi-region-dr-framework/
├── app/
│   ├── app.py              # Flask application with /write, /data, /health
│   ├── Dockerfile           # Production container with Gunicorn
│   ├── requirements.txt     # Python dependencies
│   └── .dockerignore        # Build context exclusions
├── scripts/
│   ├── backup.sh            # Database dump + compress + S3 upload
│   ├── replicate_storage.sh # Cross-region S3 replication
│   ├── dr.sh                # Failover orchestration script
│   ├── replicate_compute.sh # IaC validation for compute
│   ├── init-primary.sh      # LocalStack S3 bucket provisioning
│   └── init-dr.sh           # LocalStack DR bucket provisioning
├── iac/
│   └── main.tf              # Terraform multi-region infrastructure
├── docker-compose.yml        # Service orchestration
├── .env.example              # Environment variable template
├── DR_METRICS.md             # RTO/RPO analysis
└── README.md                 # This file
```