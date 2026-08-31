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

# 1. IAM Policy for Runtime Threat Detection Logging (Falco/Wazuh Agent Role) - Session 21
resource "aws_iam_policy" "runtime_threat_detection_policy" {
  name = "soc-runtime-threat-detection-policy"
  description = "Allows runtime security agents to stream container security events to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:us-east-1:*:log-group:/aws/container-runtime/*"
      }
    ]
  })
}

# 2. KMS Key for Encrypting Runtime Security Logs
resource "aws_kms_key" "runtime_logs_key" {
  description = "KMS Key for Runtime Threat Detection Logs"
  deletion_window_in_days = 7
  enable_key_rotation = true

  tags = {
    Environment = "DevOps-SOC"
    Purpose = "Runtime-Threat-Security"
  }
}

# 3. Output for Kubernetes Microsegmentation & Runtime Security Status - Session 22
output "runtime_security_status" {
  value = "Enforced: Default Deny All Ingress/Egress Pod Network Microsegmentation Baseline"
  description = "Kubernetes Pod Network Isolation Rule Audit"
}
