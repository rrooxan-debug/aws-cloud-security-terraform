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

# 1. CloudWatch Log Group Retention Management (Session 11)
resource "aws_cloudwatch_log_group" "soc_retention_audit_logs" {
  name = "/aws/cloudtrail/siem-baseline-retention-logs"
  retention_in_days = 90

  tags = {
    Environment = "DevOps-SOC"
    Policy = "Compliance-90Days-Retention"
  }
}

# 2. KMS Key for Log Encryption at Rest (Baseline Audit Rule - Session 12)
resource "aws_kms_key" "retention_log_key" {
  description = "KMS Key for encrypting SOC baseline audit log groups"
  deletion_window_in_days = 7
  enable_key_rotation = true

  tags = {
    Environment = "DevOps-SOC"
    Compliance = "KMS-Rotation-Enabled"
  }
}

# 3. Output for Validation
output "audit_log_group_arn" {
  value = aws_cloudwatch_log_group.soc_retention_audit_logs.arn
  description = "ARN of the SOC Audit Log Group with 90-day retention"
}
