resource "aws_s3_bucket" "securityhub_bucket" {
  bucket_prefix = "my-securityhub-exporter-"
  tags = {
    Name = "securityhub-exporter-bucket"
  }
}

resource "aws_s3_bucket_acl" "securityhub_bucket_acl" {
  bucket = aws_s3_bucket.securityhub_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "securityhub_bucket_encryption" {
  bucket = aws_s3_bucket.securityhub_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.securityhub_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "securityhub_bucket_versioning" {
  bucket = aws_s3_bucket.securityhub_bucket.id
  versioning_configuration {
    status = var.s3_versioning_status ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "default" {
  depends_on = [
    aws_s3_bucket.securityhub_bucket
  ]
  bucket = aws_s3_bucket.securityhub_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


