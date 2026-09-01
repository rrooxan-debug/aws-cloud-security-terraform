terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Unique suffix for S3 bucket name
resource "random_id" "suffix" {
  byte_length = 4
}

# 1. KMS Key for SIEM Centralized Logs Encryption (Session 26)
resource "aws_kms_key" "siem_kms_key" {
  description = "KMS Key for Centralized SIEM Log Aggregation"
  deletion_window_in_days = 7
  enable_key_rotation = true

  tags = {
    Environment = "DevOps-SOC"
    Purpose = "SIEM-Log-Encryption"
  }
}

# 2. Centralized S3 Bucket for SIEM Log Ingestion (Session 25)
resource "aws_s3_bucket" "siem_log_bucket" {
  bucket = "soc-siem-logs-aggregation-${random_id.suffix.hex}"
  force_destroy = true

  tags = {
    Environment = "DevOps-SOC"
    Purpose = "SIEM-Central-Logging"
  }
}

# 3. Block All Public Access to SIEM Bucket
resource "aws_s3_bucket_public_access_block" "siem_public_block" {
  bucket = aws_s3_bucket.siem_log_bucket.id

  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

# 4. Enforce KMS Encryption at Rest for SIEM Bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "siem_encryption" {
  bucket = aws_s3_bucket.siem_log_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.siem_kms_key.arn
      sse_algorithm = "aws:kms"
    }
  }
}

# Outputs
output "siem_s3_bucket_name" {
  value = aws_s3_bucket.siem_log_bucket.id
  description = "Centralized SIEM Log Aggregation S3 Bucket Name"
}

output "siem_kms_key_arn" {
  value = aws_kms_key.siem_kms_key.arn
  description = "KMS Encryption Key ARN for SIEM Logs"
}
