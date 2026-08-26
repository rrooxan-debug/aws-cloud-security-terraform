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

# 1. SOC Security Audit Role (Read-Only)
resource "aws_iam_role" "soc_analyst_role" {
  name = "SOC-Security-Analyst-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = "DevOps-SOC"
  }
}

# 2. Attach SecurityAudit Managed Policy (Least Privilege)
resource "aws_iam_role_policy_attachment" "soc_audit_attach" {
  role = aws_iam_role.soc_analyst_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}
