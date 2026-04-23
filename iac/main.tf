# ---------------------------------------------------------------
# Multi-Region Disaster Recovery Infrastructure
# Defines S3 buckets and EC2 compute for primary and DR regions.
# Uses variables for credentials and configuration to avoid
# hardcoding sensitive values.
# ---------------------------------------------------------------

# ---------------------
# Variables
# ---------------------
variable "primary_region" {
  description = "AWS region for primary resources"
  type        = string
  default     = "us-east-1"
}

variable "dr_region" {
  description = "AWS region for disaster recovery resources"
  type        = string
  default     = "us-west-2"
}

variable "primary_bucket_name" {
  description = "Name of the primary S3 backup bucket"
  type        = string
  default     = "my-app-backups-primary"
}

variable "dr_bucket_name" {
  description = "Name of the DR S3 backup bucket"
  type        = string
  default     = "my-app-backups-dr"
}

variable "primary_ami" {
  description = "AMI ID for the primary region EC2 instance (Amazon Linux 2)"
  type        = string
  default     = "ami-0c02fb55956c7d316" # Amazon Linux 2 AMI (us-east-1)
}

variable "dr_ami" {
  description = "AMI ID for the DR region EC2 instance (Amazon Linux 2)"
  type        = string
  default     = "ami-0892d3c7ee96c0bf7" # Amazon Linux 2 AMI (us-west-2)
}

# ---------------------
# Primary Region Provider
# ---------------------
# Credentials are sourced from environment variables or AWS CLI profile.
# For LocalStack testing, set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
# environment variables instead of hardcoding them here.
provider "aws" {
  region = var.primary_region

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  endpoints {
    s3  = "http://localhost:4566"
    ec2 = "http://localhost:4566"
  }
}

# ---------------------
# Primary S3 Bucket
# ---------------------
resource "aws_s3_bucket" "primary_backup" {
  bucket = var.primary_bucket_name
}

resource "aws_s3_bucket_versioning" "primary_versioning" {
  bucket = aws_s3_bucket.primary_backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ---------------------
# Primary EC2 Compute Instance
# ---------------------
resource "aws_instance" "primary_compute" {
  ami           = var.primary_ami
  instance_type = "t2.micro"
  tags = {
    Name        = "Primary Web App"
    Environment = "production"
    Role        = "primary"
  }
}

# ---------------------
# DR Region Provider
# ---------------------
provider "aws" {
  alias  = "dr"
  region = var.dr_region

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  endpoints {
    s3  = "http://localhost:4567"
    ec2 = "http://localhost:4567"
  }
}

# ---------------------
# DR S3 Bucket
# ---------------------
resource "aws_s3_bucket" "dr_backup" {
  provider = aws.dr
  bucket   = var.dr_bucket_name
}

resource "aws_s3_bucket_versioning" "dr_versioning" {
  provider = aws.dr
  bucket   = aws_s3_bucket.dr_backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ---------------------
# DR EC2 Compute Instance
# ---------------------
resource "aws_instance" "dr_compute" {
  provider      = aws.dr
  ami           = var.dr_ami
  instance_type = "t2.micro"
  tags = {
    Name        = "DR Web App"
    Environment = "disaster-recovery"
    Role        = "failover"
  }
}