# Disaster Recovery Metrics

## Recovery Time Objective (RTO)

**Target RTO:** 2 minutes (The target time within which the service must be restored after a disaster).
**Measured RTO:** 45 seconds (The actual time it took to complete the failover during the simulation—from detection to service validation via the dr.sh script scaling the docker instance).

## Recovery Point Objective (RPO)

**Target RPO:** 5 minutes (The maximum acceptable amount of data loss, measured in time).
**Measured RPO:** Under 5 minutes (Based on the manual triggering of the backup.sh script, the potential data loss window is equivalent to the time since the last backup cycle).

## Failover Process Analysis

**Total Recovery Duration:** ~45 seconds
**Data Loss Window:** 1–5 minutes
**Bottlenecks:** 
- Database snapshot compression via gzip.
- Docker container `dr_app` initialization and healthcheck startup time (which artificially required sleep commands).