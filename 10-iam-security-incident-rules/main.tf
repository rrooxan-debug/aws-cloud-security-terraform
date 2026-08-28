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

# 1. Metric Filter for IAM Policy Changes & Privilege Escalation Attempts
resource "aws_cloudwatch_log_metric_filter" "iam_changes_filter" {
  name = "IAMPolicyChangesFilter"
  pattern = "{ ($.eventName = DeleteGroupPolicy) || ($.eventName = DeleteRolePolicy) || ($.eventName = DeleteUserPolicy) || ($.eventName = PutGroupPolicy) || ($.eventName = PutRolePolicy) || ($.eventName = PutUserPolicy) || ($.eventName = CreatePolicy) || ($.eventName = AttachRolePolicy) || ($.eventName = AttachUserPolicy) }"
  log_group_name = "/aws/cloudtrail/siem-audit-logs"

  metric_transformation {
    name = "IAMPolicyChangeCount"
    namespace = "CloudTrailSOCMetrics"
    value = "1"
  }
}

# 2. Alarm for IAM Modifications
resource "aws_cloudwatch_metric_alarm" "iam_changes_alarm" {
  alarm_name = "HIGH-IAMPolicyModified-SOC"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 1
  metric_name = aws_cloudwatch_log_metric_filter.iam_changes_filter.metric_transformation[0].name
  namespace = aws_cloudwatch_log_metric_filter.iam_changes_filter.metric_transformation[0].namespace
  period = 60
  statistic = "Sum"
  threshold = 1
  alarm_description = "HIGH: IAM policy or role permissions modified in AWS account."
  alarm_actions = []

  tags = {
    Severity = "HIGH"
    Environment = "DevOps-SOC"
  }
}
