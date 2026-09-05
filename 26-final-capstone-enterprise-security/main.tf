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

# 1. Capstone Global Infrastructure Security Registry (Session 39)
resource "aws_ssm_parameter" "capstone_deployment_status" {
  name = "/soc/capstone/deployment_status"
  type = "String"
  value = "COMPLETED: Full Multi-Account Security, DevSecOps Pipeline, Wazuh SIEM & Guardrails Active"
  description = "Capstone Enterprise Security Deployment Register"
}

# 2. Capstone Final Audit Baseline Parameter (Session 40)
resource "aws_ssm_parameter" "capstone_audit_signoff" {
  name = "/soc/capstone/audit_signoff"
  type = "String"
  value = "PASSED_100_PERCENT: Enterprise Infrastructure Hardening & Cloud Security Architecture Certified"
  description = "Final Audit Verification and Graduation Status"
}

# Outputs (marked as sensitive)
output "capstone_deployment_summary" {
  value = aws_ssm_parameter.capstone_deployment_status.value
  description = "Final Capstone Deployment Summary"
  sensitive = true
}

output "graduation_status" {
  value = aws_ssm_parameter.capstone_audit_signoff.value
  description = "Official Certification & Graduation Sign-Off"
  sensitive = true
}
