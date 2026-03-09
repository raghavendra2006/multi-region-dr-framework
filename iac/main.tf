provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "primary_backup" {
  bucket = "primary-backups"
}

provider "aws" {
  alias  = "dr"
  region = "us-west-2"
}

resource "aws_s3_bucket" "dr_backup" {
  provider = aws.dr
  bucket   = "dr-backups"
}