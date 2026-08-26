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

# 1. SNS Topic for SOC Security Alerts
resource "aws_sns_topic" "soc_alerts" {
  name = "soc-security-alerts-topic"

  tags = {
    Environment = "DevOps-SOC"
  }
}

# 2. EventBridge Rule to Detect Unauthorized API Calls / Critical Events
resource "aws_cloudwatch_event_rule" "unauthorized_api_calls" {
  name = "detect-unauthorized-api-calls"
  description = "Triggers alert on unauthorized AWS API calls"

  event_pattern = jsonencode({
    "detail-type" = [
      "AWS API Call via CloudTrail"
    ],
    "detail" = {
      "errorCode" = [
        "AccessDenied",
        "UnauthorizedOperation"
      ]
    }
  })
}

# 3. Target: Send EventBridge Alerts to SNS Topic
resource "aws_cloudwatch_event_target" "sns_target" {
  rule = aws_cloudwatch_event_rule.unauthorized_api_calls.name
  target_id = "SendToSNS"
  arn = aws_sns_topic.soc_alerts.arn
}

# 4. Allow EventBridge to Publish to SNS
resource "aws_sns_topic_policy" "default" {
  arn = aws_sns_topic.soc_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowEventBridgeToPublish"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sns:Publish"
        Resource = aws_sns_topic.soc_alerts.arn
      }
    ]
  })
}
