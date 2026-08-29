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

# 1. SNS Topic for SOC Critical Security Alerts
resource "aws_sns_topic" "soc_security_alerts" {
  name = "soc-critical-security-alerts-topic"

  tags = {
    Environment = "DevOps-SOC"
    Purpose = "Threat-Alerting"
  }
}

# 2. SNS Topic Policy to allow CloudWatch Alarms to Publish
resource "aws_sns_topic_policy" "default" {
  arn = aws_sns_topic.soc_security_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowCloudWatchToPublish"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action = "sns:Publish"
        Resource = aws_sns_topic.soc_security_alerts.arn
      }
    ]
  })
}

# 3. Output the SNS Topic ARN for future alarm actions
output "sns_topic_arn" {
  value = aws_sns_topic.soc_security_alerts.arn
  description = "ARN of the SNS Topic for SOC Security Alerts"
}
