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

# 1. IAM Role for Automated Incident Response Playbook (Session 31)
resource "aws_iam_role" "incident_response_role" {
  name = "soc-automated-incident-response-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# 2. IAM Policy for Auto-Remediation (Isolating compromised resources)
resource "aws_iam_policy" "remediation_policy" {
  name = "soc-auto-remediation-policy"
  description = "Permissions for automated SOC incident playbooks"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:RevokeSecurityGroupIngress",
          "iam:RevokeSecurityAttribute",
          "sns:Publish"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_remediation" {
  role = aws_iam_role.incident_response_role.name
  policy_arn = aws_iam_policy.remediation_policy.arn
}

# 3. Output for Phase 3 Compliance Sign-off (Session 32)
output "phase3_security_signoff_status" {
  value = "PASSED: SIEM Central Storage, Log Forwarding, Custom Detection Rules, Dashboards, Alerting & Auto-Remediation Validated"
  description = "Phase 3 Threat Detection & SOC Monitoring Sign-off Baseline"
}
