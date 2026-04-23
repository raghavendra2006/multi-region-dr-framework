# Disaster Recovery Metrics

## Recovery Time Objective (RTO)

**Target RTO:** 2 minutes  
**Measured RTO:** 45 seconds  

The measured RTO represents the total elapsed time from primary failure detection to the DR application passing its health check. This was measured during the simulation by timing the `dr.sh --failover` script execution end-to-end.

### RTO Breakdown

| Phase | Duration | Description |
|-------|----------|-------------|
| Health Check Detection | ~2s | `curl` timeout detecting primary is down |
| S3 List + Download | ~5s | Listing DR bucket objects and downloading latest backup |
| Decompression | ~1s | `gunzip` of the compressed SQL dump |
| Database Restore | ~2s | `sqlite3` import of the SQL dump into DR database file |
| Container Startup | ~30s | `docker-compose up` for `dr_app` + Gunicorn worker init |
| Health Verification | ~5s | Retry loop confirming DR `/health` endpoint responds |
| **Total** | **~45s** | |

## Recovery Point Objective (RPO)

**Target RPO:** 5 minutes  
**Measured RPO:** Under 5 minutes  

The RPO is determined by the interval between backup executions. Since `backup.sh` is triggered manually (or could be scheduled via cron), the maximum data loss window equals the time elapsed since the last successful backup. During testing, backups were taken immediately before simulating failure, resulting in near-zero data loss.

### RPO Analysis

| Scenario | RPO | Notes |
|----------|-----|-------|
| Backup taken immediately before failure | ~0s | Best case — all data preserved |
| Backup taken on 5-min cron schedule | ≤5 min | Worst case — up to 5 minutes of writes lost |
| No recent backup available | Undefined | Catastrophic — highlights need for automated scheduling |

## Failover Process Analysis

**Total Recovery Duration:** ~45 seconds  
**Data Loss Window:** 0–5 minutes (depending on backup frequency)

### Bottlenecks Identified

1. **Docker container cold start** (~30s): The `dr_app` container must be built, started, and Gunicorn workers must initialize. This is the single largest contributor to RTO.
2. **Database dump compression via gzip** (~1s): Negligible for small databases, but could become significant with larger datasets (>1GB).
3. **S3 cross-region transfer** (~5s): Downloading the backup from the DR LocalStack bucket. In a real AWS environment, this latency would depend on bucket size and network bandwidth between regions.
4. **Sequential execution**: Each step runs serially — parallelizing S3 download with container pre-warming could reduce RTO.

### Improvement Recommendations

| Strategy | Expected RTO Reduction | Complexity |
|----------|----------------------|------------|
| **Warm Standby** — Keep `dr_app` running idle | -30s (eliminates cold start) | Low |
| **Automated cron backups** (every 1 min) | RPO reduced to ≤1 min | Low |
| **Streaming replication** (WAL shipping) | RPO reduced to ~0s | High |
| **Pre-pull DR container image** | -10s (eliminates image build) | Low |
| **Health check with shorter intervals** | -5s (faster detection) | Low |

### Monitoring Recommendations

- **Backup verification**: After each `backup.sh` run, verify the S3 object exists and its size is non-zero.
- **Cross-region sync lag**: Track the timestamp delta between the latest primary and DR bucket objects.
- **Alerting**: Configure alerts when backup age exceeds the RPO threshold (5 minutes).
- **DR drill cadence**: Perform failover drills quarterly to validate RTO/RPO targets remain achievable.