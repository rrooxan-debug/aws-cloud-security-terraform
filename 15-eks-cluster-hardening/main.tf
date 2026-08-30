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

# 1. KMS Key for Kubernetes Secrets Encryption at Rest (Session 15)
resource "aws_kms_key" "eks_kms_key" {
  description = "KMS Key for EKS Cluster Secrets Encryption"
  deletion_window_in_days = 7
  enable_key_rotation = true

  tags = {
    Environment = "DevOps-SOC"
    Purpose = "EKS-Secrets-Encryption"
  }
}

# 2. IAM Role for EKS Cluster Control Plane
resource "aws_iam_role" "eks_cluster_role" {
  name = "soc-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = aws_iam_role.eks_cluster_role.name
}

# 3. Secure EKS Control Plane Configuration (Session 15)
resource "aws_eks_cluster" "soc_cluster" {
  name = "soc-hardened-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  # Enable Control Plane Audit Logging
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_config {
    subnet_ids = ["subnet-00000000000000001", "subnet-00000000000000002"] # Mock Subnet IDs for Terraform Validation
    endpoint_private_access = true
    endpoint_public_access = false # Disable Public Endpoint for SOC Hardening
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks_kms_key.arn
    }
    resources = ["secrets"]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# 4. IAM Role for Hardened Worker Nodes (Session 16)
resource "aws_iam_role" "eks_node_role" {
  name = "soc-eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_read" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role = aws_iam_role.eks_node_role.name
}

# Outputs
output "eks_cluster_name" {
  value = aws_eks_cluster.soc_cluster.name
  description = "Name of the Hardened EKS Cluster"
}

output "eks_cluster_arn" {
  value = aws_eks_cluster.soc_cluster.arn
  description = "ARN of the EKS Cluster"
}
