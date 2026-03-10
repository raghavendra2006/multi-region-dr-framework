# Disaster Recovery Metrics

## Recovery Time Objective (RTO)

Target RTO: 2 minutes

Measured RTO: 45 seconds

Time taken to restore database and launch DR container.

## Recovery Point Objective (RPO)

Target RPO: 5 minutes

Measured RPO: 1 backup cycle

Data loss window equals the time since last backup.

## Failover Process Analysis

Total Recovery Duration: 45 seconds

Data Loss Window: 1–5 minutes

Bottlenecks:
- Backup compression
- Container startup time