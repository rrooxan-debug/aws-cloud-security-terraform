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

# 1. Metric Filter to Catch AccessDenied Errors in CloudWatch Logs
resource "aws_cloudwatch_log_metric_filter" "unauthorized_api_calls" {
  name = "UnauthorizedAPICalls"
  pattern = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"
  log_group_name = "/aws/cloudtrail/siem-audit-logs"

  metric_transformation {
    name = "UnauthorizedAttemptCount"
    namespace = "CloudTrailMetrics"
    value = "1"
  }
}

# 2. CloudWatch Alarm Triggered by Unauthorized Calls
resource "aws_cloudwatch_metric_alarm" "unauthorized_api_alarm" {
  alarm_name = "UnauthorizedAPICalls-SOC-Alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 1
  metric_name = aws_cloudwatch_log_metric_filter.unauthorized_api_calls.metric_transformation[0].name
  namespace = aws_cloudwatch_log_metric_filter.unauthorized_api_calls.metric_transformation[0].namespace
  period = 60
  statistic = "Sum"
  threshold = 1
  alarm_description = "Alarm triggers when unauthorized API calls exceed 1 in 60 seconds."
  alarm_actions = []

  tags = {
    Environment = "DevOps-SOC"
  }
}
