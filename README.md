# AWS Cloud Security Infrastructure with Terraform

A production-grade infrastructure portfolio demonstrating core **Cloud Security Engineering** practices on AWS using Terraform.

## 🏗️ Architecture Overview

This repository consists of three modular automated security tracks:

### 1. Secure VPC Network Architecture (`01-secure-vpc-architecture`)
- **Hardened VPC Baseline:** Custom CIDR block with segmented public and private subnets.
- **Outbound Traffic Control:** NAT Gateway routing for private subnet instances.
- **Network Access Control:** Restricted Security Group policies eliminating open administrative access.

### 2. Centralized CloudTrail Audit Pipeline (`02-cloudtrail-audit-pipeline`)
- **Multi-Region Auditing:** AWS CloudTrail recording all API calls across the account.
- **S3 Audit Storage:** Public Access Blocked S3 bucket enforced with strict bucket policies.
- **KMS Encryption:** Secure log delivery with bucket ownership controls.

### 3. Zero-Trust KMS & IAM Policy Baseline (`03-zerotrust-kms-iam`)
- **Automated Key Rotation:** Customer Managed KMS Key (CMK) configured with annual key rotation.
- **Principle of Least Privilege:** IAM Roles and Policies scoped strictly to specific KMS resources (no wildcard `*` permissions).

---

## 🚀 Deployment Instructions

### Prerequisites
- AWS CLI configured
- Terraform >= 1.5.0

### Run Infrastructure
```bash
cd 01-secure-vpc-architecture
terraform init
terraform apply

