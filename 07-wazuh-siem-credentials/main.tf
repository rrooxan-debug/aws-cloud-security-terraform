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

# 1. Dedicated IAM User for Wazuh / SIEM Integration
resource "aws_iam_user" "wazuh_siem_user" {
  name = "Wazuh-SIEM-Log-Reader"

  tags = {
    Environment = "DevOps-SOC"
    Purpose = "SIEM-Integration"
  }
}

# 2. Least-Privilege IAM Policy for Log Ingestion
resource "aws_iam_user_policy" "wazuh_siem_policy" {
  name = "WazuhSIEMReadLogsPolicy"
  user = aws_iam_user.wazuh_siem_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::soc-siem-logs-ingestion-*",
          "arn:aws:s3:::soc-siem-logs-ingestion-*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}
