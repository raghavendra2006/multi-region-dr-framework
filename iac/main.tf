provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  endpoints {
    s3  = "http://localhost:4566"
    ec2 = "http://localhost:4566"
  }
}

resource "aws_s3_bucket" "primary_backup" {
  bucket = "my-app-backups-primary"
}

resource "aws_s3_bucket_versioning" "primary_versioning" {
  bucket = aws_s3_bucket.primary_backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_instance" "primary_compute" {
  ami           = "ami-12345"
  instance_type = "t2.micro"
  tags = {
    Name = "Primary Web App"
  }
}

provider "aws" {
  alias                       = "dr"
  region                      = "us-west-2"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  endpoints {
    s3  = "http://localhost:4567"
    ec2 = "http://localhost:4567"
  }
}

resource "aws_s3_bucket" "dr_backup" {
  provider = aws.dr
  bucket   = "my-app-backups-dr"
}

resource "aws_s3_bucket_versioning" "dr_versioning" {
  provider = aws.dr
  bucket   = aws_s3_bucket.dr_backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_instance" "dr_compute" {
  provider      = aws.dr
  ami           = "ami-12345"
  instance_type = "t2.micro"
  tags = {
    Name = "DR Web App"
  }
}