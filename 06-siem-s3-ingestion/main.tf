terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# 1. Random suffix for unique S3 bucket name
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# 2. Dedicated S3 Bucket for SIEM Log Ingestion
resource "aws_s3_bucket" "siem_ingestion_bucket" {
  bucket = "soc-siem-logs-ingestion-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Environment = "DevOps-SOC"
    Purpose = "SIEM-Integration"
  }
}

# 3. Server-side Encryption (AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "siem_logs_encryption" {
  bucket = aws_s3_bucket.siem_ingestion_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 4. Block All Public Access (Security Best Practice)
resource "aws_s3_bucket_public_access_block" "siem_logs_public_block" {
  bucket = aws_s3_bucket.siem_ingestion_bucket.id

  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}
