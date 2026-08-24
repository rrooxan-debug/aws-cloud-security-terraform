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

data "aws_caller_identity" "current" {}

# --- KMS KEY FOR CLOUDWATCH LOGS ---
resource "aws_kms_key" "soc_kms_key" {
  #checkov:skip=CKV2_AWS_64: Key policy defined directly for SOC KMS deployment
  description = "KMS Key for SOC CloudWatch Log Group Encryption"
  deletion_window_in_days = 30
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "kms:*"
        Resource = "*"
      },
      {
        Sid = "Allow CloudWatch Logs Access"
        Effect = "Allow"
        Principal = {
          Service = "logs.us-east-1.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
      }
    ]
  })
}

# --- CLOUDWATCH LOG GROUP FOR SOC AUDITING ---
resource "aws_cloudwatch_log_group" "soc_security_logs" {
  name = "/aws/soc/security-audit-logs"
  retention_in_days = 365
  kms_key_id = aws_kms_key.soc_kms_key.arn
}

# --- EVENTBRIDGE RULE FOR SECURITY ALERTS ---
resource "aws_cloudwatch_event_rule" "unauthorized_api_calls" {
  name = "soc-unauthorized-api-calls"
  description = "Triggers alert on Unauthorized AWS API Calls for SIEM Monitoring"

  event_pattern = jsonencode({
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      errorCode = [
        "AccessDenied",
        "UnauthorizedOperation"
      ]
    }
  })
}

# --- EVENTBRIDGE TARGET TO CLOUDWATCH LOGS ---
resource "aws_cloudwatch_event_target" "log_target" {
  rule = aws_cloudwatch_event_rule.unauthorized_api_calls.name
  target_id = "SendToCloudWatchLogs"
  arn = aws_cloudwatch_log_group.soc_security_logs.arn
}
