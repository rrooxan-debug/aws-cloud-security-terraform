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

# 1. SNS Topic for SOC Critical Security Incident Escalation (Session 30)
resource "aws_sns_topic" "soc_incident_alerts" {
  name = "soc-critical-incident-alerts"
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Environment = "DevOps-SOC"
    Purpose = "Incident-Escalation-Alerting"
  }
}

# 2. Metric Filter for High-Severity SIEM Alerts (Session 29)
resource "aws_cloudwatch_log_metric_filter" "siem_high_severity_events" {
  name = "siem-high-severity-security-events"
  pattern = "{ ($.eventSource = \"iam.amazonaws.com\") && ($.eventName = \"CreateUser\" || $.eventName = \"AttachUserPolicy\") }"
  log_group_name = "/aws/eks/soc-hardened-eks-cluster/cluster"

  metric_transformation {
    name = "HighSeveritySecurityEvents"
    namespace = "SOC/SIEM"
    value = "1"
  }
}

# 3. CloudWatch Alarm for Real-Time Threat Escalation (Session 30)
resource "aws_cloudwatch_metric_alarm" "siem_threat_escalation_alarm" {
  alarm_name = "soc-high-severity-threat-detected"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 1
  metric_name = aws_cloudwatch_log_metric_filter.siem_high_severity_events.metric_transformation[0].name
  namespace = aws_cloudwatch_log_metric_filter.siem_high_severity_events.metric_transformation[0].namespace
  period = 60
  statistic = "Sum"
  threshold = 1
  alarm_description = "Triggers when high-severity security events occur"
  alarm_actions = [aws_sns_topic.soc_incident_alerts.arn]

  tags = {
    Environment = "DevOps-SOC"
    Severity = "CRITICAL"
  }
}

# Outputs
output "sns_incident_topic_arn" {
  value = aws_sns_topic.soc_incident_alerts.arn
  description = "SNS Topic ARN for Critical SOC Escalations"
}

output "siem_alarm_status" {
  value = aws_cloudwatch_metric_alarm.siem_threat_escalation_alarm.alarm_name
  description = "CloudWatch Alarm configured for SIEM Escalation"
}
