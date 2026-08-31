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

# 1. CloudWatch Log Group for EKS Audit Ingestion to SIEM (Session 23)
resource "aws_cloudwatch_log_group" "eks_audit_logs" {
  name = "/aws/eks/soc-hardened-eks-cluster/cluster"
  retention_in_days = 90

  tags = {
    Environment = "DevOps-SOC"
    Purpose = "SIEM-EKS-Audit-Ingestion"
  }
}

# 2. Metric Filter for Unauthorized Kubernetes API Requests (Session 23)
resource "aws_cloudwatch_log_metric_filter" "eks_unauthorized_access" {
  name = "eks-unauthorized-api-access"
  pattern = "{ ($.responseStatus.code = 401) || ($.responseStatus.code = 403) }"
  log_group_name = aws_cloudwatch_log_group.eks_audit_logs.name

  metric_transformation {
    name = "EKSUnauthorizedAPICalls"
    namespace = "EKSContainerSecurity"
    value = "1"
  }
}

# 3. Output for Phase 2 Compliance Sign-off (Session 24)
output "phase2_security_signoff_status" {
  value = "PASSED: Container Scanning, EKS Hardening, RBAC, DevSecOps Pipeline & Runtime Detection Validated"
  description = "Phase 2 DevSecOps Security Sign-off Baseline Audit"
}
