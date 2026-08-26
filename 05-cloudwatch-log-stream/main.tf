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

# 1. CloudWatch Log Group for Security Audits
resource "aws_cloudwatch_log_group" "siem_audit_logs" {
  name = "/aws/cloudtrail/siem-audit-logs"
  retention_in_days = 14

  tags = {
    Environment = "DevOps-SOC"
    Purpose = "SIEM-Log-Ingestion"
  }
}

# 2. IAM Role allowing CloudTrail to write to CloudWatch Logs
resource "aws_iam_role" "cloudtrail_cw_role" {
  name = "CloudTrail-To-CloudWatch-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      }
    ]
  })
}

# 3. IAM Policy for CloudWatch Log Stream Actions
resource "aws_iam_role_policy" "cloudtrail_cw_policy" {
  name = "CloudTrail-CW-Policy"
  role = aws_iam_role.cloudtrail_cw_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.siem_audit_logs.arn}:*"
      }
    ]
  })
}
