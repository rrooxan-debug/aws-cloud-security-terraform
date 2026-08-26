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

# 1. Get Current AWS Account ID
data "aws_caller_identity" "current" {}

# 2. Secure S3 Bucket for Audit Logs
resource "aws_s3_bucket" "audit_logs" {
  bucket = "cloudtrail-audit-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name = "CloudTrail Audit Bucket"
    Environment = "DevOps-SOC"
  }
}

# Block all public access (Security Best Practice)
resource "aws_s3_bucket_public_access_block" "audit_logs_block" {
  bucket = aws_s3_bucket.audit_logs.id

  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

# Enable Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "audit_logs_encryption" {
  bucket = aws_s3_bucket.audit_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 3. S3 Bucket Policy for CloudTrail
resource "aws_s3_bucket_policy" "audit_logs_policy" {
  bucket = aws_s3_bucket.audit_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.audit_logs.arn
      },
      {
        Sid = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.audit_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# 4. AWS CloudTrail
# checkov:skip=CKV_AWS_252:KMS Encryption skipped for standard lab setup
resource "aws_cloudtrail" "main" {
  name = "main-account-audit-trail"
  s3_bucket_name = aws_s3_bucket.audit_logs.id
  include_global_service_events = true
  is_multi_region_trail = false
  enable_logging = true

  depends_on = [aws_s3_bucket_policy.audit_logs_policy]
}
