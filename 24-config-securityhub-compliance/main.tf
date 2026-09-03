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

# 1. IAM Role for AWS Config Service (Session 35)
resource "aws_iam_role" "config_role" {
  name = "soc-aws-config-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "config_role_attach" {
  role = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# 2. S3 Bucket for AWS Config Snapshots
resource "aws_s3_bucket" "config_bucket" {
  bucket = "soc-aws-config-snapshots-bucket"
  force_destroy = true
}

# 3. AWS Config Recorder
resource "aws_config_configuration_recorder" "config_recorder" {
  name = "soc-aws-config-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported = true
    include_global_resource_types = true
  }
}

# 4. AWS Config Rule: Enforce S3 Bucket Encrypted at Rest (Session 35)
resource "aws_config_config_rule" "s3_server_side_encryption" {
  name = "s3-bucket-server-side-encryption-enabled"
  description = "Checks whether S3 buckets have server-side encryption enabled"
  depends_on = [aws_config_configuration_recorder.config_recorder]

  source {
    owner = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }
}

# 5. Enable AWS Security Hub (Session 36)
resource "aws_securityhub_account" "soc_security_hub" {}

# Outputs
output "aws_config_rule_status" {
  value = aws_config_config_rule.s3_server_side_encryption.arn
  description = "AWS Config Compliance Rule ARN"
}

output "security_hub_status" {
  value = aws_securityhub_account.soc_security_hub.id
  description = "AWS Security Hub Account Status"
}
