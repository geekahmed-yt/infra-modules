resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
  tags          = var.tags
}

# Object Ownership: disable ACLs (recommended)  
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id
  rule { object_ownership = var.object_ownership_mode }
}

# Block Public Access (all four switches)
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = var.block_public_access
  block_public_policy     = var.block_public_access
  ignore_public_acls      = var.block_public_access
  restrict_public_buckets = var.block_public_access
}

# Default encryption: SSE-S3 by default, optional SSE-KMS  
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_mode == "SSE-KMS" ? "aws:kms" : "AES256"
      kms_master_key_id = var.sse_mode == "SSE-KMS" ? var.kms_key_arn : null
    }
    bucket_key_enabled = var.sse_mode == "SSE-KMS" ? var.bucket_key_enabled : false
  }
}

# Versioning
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration { status = var.enable_versioning ? "Enabled" : "Suspended" }
}

# Lifecycle: abort incomplete multipart uploads (cost control)  
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = var.enable_abort_incomplete_mpu ? 1 : 0
  bucket = aws_s3_bucket.this.id
  rule {
    id     = "abort-incomplete-mpu"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = var.abort_incomplete_mpu_after_days
    }
  }
}

resource "aws_s3_bucket_policy" "enforce_tls" {
  count  = var.enforce_tls_only ? 1 : 0
  bucket = aws_s3_bucket.this.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "DenyInsecureTransport",
      Effect    = "Deny",
      Principal = "*",
      Action    = "s3:*",
      Resource  = [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"],
      Condition = { Bool = { "aws:SecureTransport" = false } }
    }]
  })
  depends_on = [aws_s3_bucket_public_access_block.this]
}

resource "aws_s3_bucket_logging" "this" {
  count         = var.access_log_bucket_id == null ? 0 : 1
  bucket        = aws_s3_bucket.this.id
  target_bucket = var.access_log_bucket_id
  target_prefix = var.access_log_prefix
  depends_on    = [aws_s3_bucket_ownership_controls.this]
}