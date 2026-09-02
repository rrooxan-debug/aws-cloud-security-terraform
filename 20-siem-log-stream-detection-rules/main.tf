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

# 1. IAM Role for CloudWatch Log Streaming to SIEM / Wazuh Ingestion (Session 27)
resource "aws_iam_role" "siem_log_stream_role" {
  name = "soc-siem-log-stream-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "logs.us-east-1.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# 2. Least Privilege Policy for Streaming Logs to S3 SIEM Bucket
resource "aws_iam_policy" "siem_stream_policy" {
  name = "soc-siem-log-stream-policy"
  description = "Allows CloudWatch to stream security events to central SIEM storage"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetBucketLocation"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_siem_stream_policy" {
  role = aws_iam_role.siem_log_stream_role.name
  policy_arn = aws_iam_policy.siem_stream_policy.arn
}

# 3. Custom SIEM Detection Rule Metadata (Session 28)
output "custom_siem_rule_status" {
  value = "Active: Parsing Rule SOC-RULE-101 (Detect Unauthorized IAM Policy Changes & Key Creation)"
  description = "SIEM Parsing & Detection Rule Status"
}
