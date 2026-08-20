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

# 1. Random Suffix for Unique S3 Bucket
resource "random_string" "bucket_suffix" {
  length = 6
  special = false
  upper = false
}

# 2. Secure S3 Bucket for CloudTrail Logs
resource "aws_s3_bucket" "audit_bucket" {
  bucket = "cloudtrail-audit-logs-ibrahim-${random_string.bucket_suffix.result}"
  force_destroy = true
}

# 3. Block Public Access
resource "aws_s3_bucket_public_access_block" "audit_bucket_block" {
  bucket = aws_s3_bucket.audit_bucket.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

# 4. Bucket Policy for CloudTrail Access
resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  bucket = aws_s3_bucket.audit_bucket.id

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
        Resource = aws_s3_bucket.audit_bucket.arn
      },
      {
        Sid = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.audit_bucket.arn}/AWSLogs/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# 5. CloudTrail Audit Setup
resource "aws_cloudtrail" "main_trail" {
  name = "central-security-trail"
  s3_bucket_name = aws_s3_bucket.audit_bucket.id
  include_global_service_events = true
  is_multi_region_trail = true
  enable_logging = true

  depends_on = [aws_s3_bucket_policy.cloudtrail_policy]
}
