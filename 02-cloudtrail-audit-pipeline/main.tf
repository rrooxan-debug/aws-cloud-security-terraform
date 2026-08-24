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

data "aws_caller_identity" "current" {}

# --- KMS KEY & ENCRYPTION ---
resource "aws_kms_key" "sec_key" {
  #checkov:skip=CKV2_AWS_64: Key policy defined directly for KMS lab deployment
  description = "KMS Key for S3 Bucket Encryption"
  deletion_window_in_days = 30
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "kms:*"
        Resource = "*"
      }
    ]
  })
}

# --- CLOUDTRAIL MAIN BUCKET ---
resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket = "my-secure-cloudtrail-audit-bucket-101"
  force_destroy = true
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  rule {
    id = "log-expiration"
    status = "Enabled"

    expiration {
      days = 365
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_logging" "audit_logging" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  target_bucket = aws_s3_bucket.cloudtrail_bucket.id
  target_prefix = "log/"
}

resource "aws_s3_bucket_public_access_block" "audit_bucket_public_block" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit_bucket_crypto" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.sec_key.arn
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "audit_bucket_versioning" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# --- REPLICA BUCKET & SECURITY ---
resource "aws_s3_bucket" "replica_bucket" {
  bucket = "my-secure-cloudtrail-replica-bucket-101"
  force_destroy = true
}

resource "aws_s3_bucket_lifecycle_configuration" "replica_lifecycle" {
  bucket = aws_s3_bucket.replica_bucket.id

  rule {
    id = "replica-log-expiration"
    status = "Enabled"

    expiration {
      days = 365
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_logging" "replica_logging" {
  bucket = aws_s3_bucket.replica_bucket.id
  target_bucket = aws_s3_bucket.replica_bucket.id
  target_prefix = "replica-log/"
}

resource "aws_s3_bucket_public_access_block" "replica_bucket_public_block" {
  bucket = aws_s3_bucket.replica_bucket.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "replica_bucket_crypto" {
  bucket = aws_s3_bucket.replica_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.sec_key.arn
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "replica_versioning" {
  bucket = aws_s3_bucket.replica_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  role = aws_iam_role.replication_role.arn
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  rule {
    id = "replicate-all"
    status = "Enabled"

    destination {
      bucket = aws_s3_bucket.replica_bucket.arn
      account_id = data.aws_caller_identity.current.account_id
      storage_class = "STANDARD"
    }
  }
}

resource "aws_iam_role" "replication_role" {
  name = "s3-replication-role-unique-101"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "replication_policy" {
  name = "s3-replication-policy-unique-101"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.cloudtrail_bucket.arn,
          "${aws_s3_bucket.cloudtrail_bucket.arn}/*"
        ]
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Effect = "Allow"
        Resource = "${aws_s3_bucket.replica_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "replication_attachment" {
  role = aws_iam_role.replication_role.name
  policy_arn = aws_iam_policy.replication_policy.arn
}

# --- NOTIFICATIONS & SNS ENCRYPTION ---
resource "aws_sns_topic" "bucket_notifications" {
  name = "s3-bucket-notifications-topic"
  kms_master_key_id = aws_kms_key.sec_key.id
}

resource "aws_s3_bucket_notification" "bucket_notif" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  sns_topic {
    sns_topic_arn = aws_sns_topic.bucket_notifications.arn
    events = ["s3:ObjectCreated:*"]
  }
}

resource "aws_s3_bucket_notification" "replica_notif" {
  bucket = aws_s3_bucket.replica_bucket.id

  sns_topic {
    sns_topic_arn = aws_sns_topic.bucket_notifications.arn
    events = ["s3:ObjectCreated:*"]
  }
}
