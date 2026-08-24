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

# 1. Get AWS Account ID
data "aws_caller_identity" "current" {}

# 2. KMS Key with Auto Rotation
resource "aws_kms_key" "sec_key" {
  description = "Zero-Trust Encryption Key with Auto Rotation"
  deletion_window_in_days = 7
  enable_key_rotation = true

  tags = {
    Name = "ibrahim-zero-trust-key"
    Environment = "Production"
  }
}

# 3. KMS Key Alias
resource "aws_kms_alias" "sec_key_alias" {
  name = "alias/ibrahim-sec-key"
  target_key_id = aws_kms_key.sec_key.key_id
}

# 4. IAM Role
resource "aws_iam_role" "app_sec_role" {
  name = "ZeroTrustApplicationRole"

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
}

# 5. Strict Zero-Trust IAM Policy
resource "aws_iam_policy" "kms_use_policy" {
  name = "KMSStrictUsePolicy"
  description = "Allows Encrypt/Decrypt ONLY on specific KMS Key"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.sec_key.arn
      }
    ]
  })
}

# 6. Policy Attachment
resource "aws_iam_role_policy_attachment" "role_kms_attach" {
  role = aws_iam_role.app_sec_role.name
  policy_arn = aws_iam_policy.kms_use_policy.arn
}
