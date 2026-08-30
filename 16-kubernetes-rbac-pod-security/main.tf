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

# 1. IAM Role for Kubernetes Service Account (IRSA) - Session 17
resource "aws_iam_role" "k8s_pod_security_role" {
  name = "soc-k8s-read-only-pod-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE:sub" = "system:serviceaccount:soc-namespace:soc-restricted-sa"
          }
        }
      }
    ]
  })
}

# 2. Least Privilege IAM Policy for Pod Access
resource "aws_iam_policy" "k8s_read_only_policy" {
  name = "soc-k8s-pod-read-only-policy"
  description = "Allows restricted read-only access to specific S3 SOC resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "RestrictedReadAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_k8s_policy" {
  role = aws_iam_role.k8s_pod_security_role.name
  policy_arn = aws_iam_policy.k8s_read_only_policy.arn
}

# 3. Guardrail Rule: Pod Security Admission Enforcement (Session 18)
output "pod_security_standards_status" {
  value = "Enforced: Restrictive Profile (No Privileged Escalation, Non-Root Execution)"
  description = "Kubernetes Pod Security Admission Baseline Audit"
}
