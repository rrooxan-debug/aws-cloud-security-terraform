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

# 1. SCP Policy: Deny Disabling CloudTrail & CloudWatch Logging (Session 34)
resource "aws_organizations_policy" "deny_disabling_logs" {
  name = "soc-deny-disabling-security-logs"
  description = "Prevents any member account from stopping CloudTrail or deleting CloudWatch log groups"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "PreventLogDeletion"
        Effect = "Deny"
        Action = [
          "cloudtrail:StopLogging",
          "cloudtrail:DeleteTrail",
          "logs:DeleteLogGroup",
          "logs:DeleteLogStream"
        ]
        Resource = "*"
      }
    ]
  })
}

# 2. SCP Policy: Enforce Region Restriction (Deny Unauthorized AWS Regions)
resource "aws_organizations_policy" "restrict_regions" {
  name = "soc-restrict-unauthorized-regions"
  description = "Restricts deployment of AWS resources outside authorized security regions"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "DenyUnapprovedRegions"
        Effect = "Deny"
        NotAction = [
          "iam:*",
          "organizations:*",
          "route53:*",
          "cloudfront:*",
          "sts:*"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = ["us-east-1"]
          }
        }
      }
    ]
  })
}

# Outputs for Enterprise Multi-Account Governance (Session 33)
output "deny_log_deletion_scp_arn" {
  value = aws_organizations_policy.deny_disabling_logs.arn
  description = "Service Control Policy ARN for Logging Governance"
}

output "restrict_regions_scp_arn" {
  value = aws_organizations_policy.restrict_regions.arn
  description = "Service Control Policy ARN for Regional Restriction Governance"
}
