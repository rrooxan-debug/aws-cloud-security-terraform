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

# 1. Metric Filter: Root Account Login Detection (Session 5)
resource "aws_cloudwatch_log_metric_filter" "root_login_filter" {
  name = "RootAccountUsageFilter"
  pattern = "{ ($.userIdentity.type = \"Root\") && ($.userIdentity.invokedBy NOT EXISTS) && ($.eventType != \"AwsServiceEvent\") }"
  log_group_name = "/aws/cloudtrail/siem-audit-logs"

  metric_transformation {
    name = "RootAccountUsageCount"
    namespace = "CloudTrailSOCMetrics"
    value = "1"
  }
}

# Alarm for Root Account Activity
resource "aws_cloudwatch_metric_alarm" "root_login_alarm" {
  alarm_name = "CRITICAL-RootAccountUsage-SOC"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 1
  metric_name = aws_cloudwatch_log_metric_filter.root_login_filter.metric_transformation[0].name
  namespace = aws_cloudwatch_log_metric_filter.root_login_filter.metric_transformation[0].namespace
  period = 60
  statistic = "Sum"
  threshold = 1
  alarm_description = "CRITICAL: Root account activity detected in AWS environment."
  alarm_actions = []

  tags = {
    Severity = "CRITICAL"
    Environment = "DevOps-SOC"
  }
}

# 2. Metric Filter: Security Group Changes Detection (Session 6)
resource "aws_cloudwatch_log_metric_filter" "sg_changes_filter" {
  name = "SecurityGroupChangesFilter"
  pattern = "{ ($.eventName = AuthorizeSecurityGroupIngress) || ($.eventName = RevokeSecurityGroupIngress) || ($.eventName = AuthorizeSecurityGroupEgress) || ($.eventName = RevokeSecurityGroupEgress) }"
  log_group_name = "/aws/cloudtrail/siem-audit-logs"

  metric_transformation {
    name = "SecurityGroupChangeCount"
    namespace = "CloudTrailSOCMetrics"
    value = "1"
  }
}

# Alarm for Security Group Changes
resource "aws_cloudwatch_metric_alarm" "sg_changes_alarm" {
  alarm_name = "HIGH-SecurityGroupModified-SOC"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 1
  metric_name = aws_cloudwatch_log_metric_filter.sg_changes_filter.metric_transformation[0].name
  namespace = aws_cloudwatch_log_metric_filter.sg_changes_filter.metric_transformation[0].namespace
  period = 60
  statistic = "Sum"
  threshold = 1
  alarm_description = "HIGH: Security group inbound/outbound rules modified."
  alarm_actions = []

  tags = {
    Severity = "HIGH"
    Environment = "DevOps-SOC"
  }
}
