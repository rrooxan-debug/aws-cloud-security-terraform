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

# 1. Metric Filter for S3 Bucket Policy & Access Violations
resource "aws_cloudwatch_log_metric_filter" "s3_bucket_policy_filter" {
  name = "S3BucketPolicyChangesFilter"
  pattern = "{ ($.eventSource = s3.amazonaws.com) && (($.eventName = PutBucketPolicy) || ($.eventName = DeleteBucketPolicy) || ($.eventName = PutBucketAcl) || ($.eventName = PutBucketPublicAccessBlock)) }"
  log_group_name = "/aws/cloudtrail/siem-audit-logs"

  metric_transformation {
    name = "S3PolicyChangeCount"
    namespace = "CloudTrailSOCMetrics"
    value = "1"
  }
}

# 2. Alarm for S3 Security Policy Changes
resource "aws_cloudwatch_metric_alarm" "s3_policy_changes_alarm" {
  alarm_name = "HIGH-S3BucketPolicyModified-SOC"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 1
  metric_name = aws_cloudwatch_log_metric_filter.s3_bucket_policy_filter.metric_transformation[0].name
  namespace = aws_cloudwatch_log_metric_filter.s3_bucket_policy_filter.metric_transformation[0].namespace
  period = 60
  statistic = "Sum"
  threshold = 1
  alarm_description = "HIGH: S3 bucket policy or public access configuration modified."
  alarm_actions = []

  tags = {
    Severity = "HIGH"
    Environment = "DevOps-SOC"
  }
}
