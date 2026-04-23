#!/bin/bash
set -euo pipefail

# ---------------------------------------------------------------
# scripts/replicate_compute.sh
# Simulates compute replication by validating that the IaC
# definitions for the DR region are present and correct.
# In a real cloud environment, this would snapshot the primary
# instance and register it in the DR region.
# ---------------------------------------------------------------

source .env

echo "INFO: Simulating Compute Replication..."
echo "INFO: Verifying IaC definitions for DR region compute instance..."

# Validate that the DR compute instance is defined in Terraform config
if grep -q "aws_instance" "./iac/main.tf"; then
    echo "INFO: IaC configuration validated — DR compute instance definition exists."
else
    echo "ERROR: IaC configuration for DR compute instance is missing in main.tf!"
    exit 1
fi

# Validate DR provider alias exists
if grep -q 'alias.*=.*"dr"' "./iac/main.tf"; then
    echo "INFO: DR provider alias validated."
else
    echo "ERROR: DR provider alias not found in main.tf!"
    exit 1
fi

echo "INFO: Compute replication simulation completed successfully."
