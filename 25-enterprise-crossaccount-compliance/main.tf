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

# 1. IAM Role for Enterprise Cross-Account Security Incident Automation (Session 37)
resource "aws_iam_role" "cross_account_soc_role" {
  name = "soc-cross-account-incident-response-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = "o-enterprise-soc-org-id"
          }
        }
      }
    ]
  })
}

# 2. Enterprise Audit Compliance Aggregator Baseline (Session 38)
resource "aws_config_configuration_aggregator" "org_compliance_aggregator" {
  name = "soc-enterprise-global-compliance-aggregator"

  account_aggregation_source {
    account_ids = ["123456789012"]
    regions = ["us-east-1"]
  }
}

# Outputs
output "cross_account_role_arn" {
  value = aws_iam_role.cross_account_soc_role.arn
  description = "IAM Role ARN for Cross-Account SOC Automation"
}

output "compliance_aggregator_status" {
  value = aws_config_configuration_aggregator.org_compliance_aggregator.arn
  description = "AWS Config Aggregator ARN for Enterprise Executive Audit Reporting"
}
