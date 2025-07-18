# Terraform configuration with intentional security misconfigurations
# This file is designed for testing security scanning tools like Wiz CLI

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# S3 bucket with multiple security misconfigurations
resource "aws_s3_bucket" "vulnerable_bucket" {
  bucket = "wiz-security-test-bucket-${random_string.bucket_suffix.result}"
  
  tags = {
    Name        = "Vulnerable Test Bucket"
    Environment = "Test"
    Purpose     = "Security Testing"
  }
}

# Random string for unique bucket naming
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# MISCONFIGURATION 1: Public read access - allows anyone to list and read bucket contents
resource "aws_s3_bucket_public_access_block" "vulnerable_bucket_pab" {
  bucket = aws_s3_bucket.vulnerable_bucket.id

  # These should be true for security, but setting to false for testing
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# MISCONFIGURATION 2: Bucket policy allowing public read access
resource "aws_s3_bucket_policy" "vulnerable_bucket_policy" {
  bucket = aws_s3_bucket.vulnerable_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.vulnerable_bucket.arn,
          "${aws_s3_bucket.vulnerable_bucket.arn}/*"
        ]
      },
      {
        Sid       = "PublicWriteAccess"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.vulnerable_bucket.arn}/*"
      }
    ]
  })
}

# MISCONFIGURATION 3: Bucket ACL allowing public read and write
resource "aws_s3_bucket_acl" "vulnerable_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.vulnerable_bucket_acl_ownership]
  
  bucket = aws_s3_bucket.vulnerable_bucket.id
  acl    = "public-read-write"
}

# Required for ACL to work
resource "aws_s3_bucket_ownership_controls" "vulnerable_bucket_acl_ownership" {
  bucket = aws_s3_bucket.vulnerable_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# MISCONFIGURATION 4: No encryption at rest
# (By not defining aws_s3_bucket_server_side_encryption_configuration)

# MISCONFIGURATION 5: No versioning enabled
# (By not defining aws_s3_bucket_versioning)

# MISCONFIGURATION 6: No logging enabled
# (By not defining aws_s3_bucket_logging)

# MISCONFIGURATION 7: No lifecycle policy to manage costs
# (By not defining aws_s3_bucket_lifecycle_configuration)

# MISCONFIGURATION 8: CORS configuration that's too permissive
resource "aws_s3_bucket_cors_configuration" "vulnerable_bucket_cors" {
  bucket = aws_s3_bucket.vulnerable_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# MISCONFIGURATION 9: No MFA delete protection
# (This would require root account access to enable via CLI)

# MISCONFIGURATION 10: No notification configuration for security events
# (By not defining aws_s3_bucket_notification)

# Output the bucket information for reference
output "bucket_name" {
  description = "Name of the vulnerable S3 bucket"
  value       = aws_s3_bucket.vulnerable_bucket.id
}

output "bucket_arn" {
  description = "ARN of the vulnerable S3 bucket"
  value       = aws_s3_bucket.vulnerable_bucket.arn
}

output "bucket_domain_name" {
  description = "Domain name of the vulnerable S3 bucket"
  value       = aws_s3_bucket.vulnerable_bucket.bucket_domain_name
}

output "security_warnings" {
  description = "List of intentional security misconfigurations"
  value = [
    "Public read/write access enabled",
    "No encryption at rest",
    "No versioning enabled",
    "No access logging",
    "Overly permissive CORS policy",
    "No lifecycle management",
    "Public ACL permissions",
    "No MFA delete protection"
  ]
}