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

resource "aws_kms_key" "log_key" {
  description = "KMS Key for CloudWatch Log Group"
  deletion_window_in_days = 30
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = "kms:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "secure-vpc"
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  ingress = []
  egress = []
}

resource "aws_flow_log" "vpc_flow_log" {
  traffic_type = "ALL"
  vpc_id = aws_vpc.main.id
  log_destination_type = "cloud-watch-logs"
  log_destination = aws_cloudwatch_log_group.vpc_log_group.arn
  iam_role_arn = aws_iam_role.vpc_flow_log_role.arn
}

resource "aws_cloudwatch_log_group" "vpc_log_group" {
  name = "/aws/vpc/flow-logs"
  retention_in_days = 365
  kms_key_id = aws_kms_key.log_key.arn
resource "aws_instance" "web_server" {
  ami = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public_subnet.id

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  metadata_options {
    http_endpoint = "enabled"
    http_tokens = "required"
  }

  tags = {
    Name = "web-server"
  }
}

resource "aws_security_group" "web_sg" {
  name = "secure-web-sg"
  description = "Allow inbound web traffic and restrict management access"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "Allow HTTP traffic"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "Allow HTTPS traffic"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "Allow restricted outbound traffic"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    Name = "web-security-group"
  }
}
