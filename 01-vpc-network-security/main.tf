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

# 1. Custom VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "secure-vpc"
    Environment = "DevOps-SOC"
  }
}

# 2. Public Subnet
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = false # Security Best Practice: Don't auto-assign public IPs

  tags = {
    Name = "public-subnet-01"
  }
}

# 3. Private Subnet (SOC Workloads)
resource "aws_subnet" "private" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "private-subnet-01"
  }
}

# 4. Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}
