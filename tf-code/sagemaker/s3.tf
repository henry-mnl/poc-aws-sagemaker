####################################################################################################
# Sagemaker Domain Bucket - to store artifacts
####################################################################################################
resource "aws_s3_bucket" "sagemaker-bucket" {
  bucket = "poc-sagemaker-bucket"
}

resource "aws_s3_bucket_versioning" "sagemaker-bucket-versioning" {
  bucket = aws_s3_bucket.sagemaker-bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sagemaker-bucket-encryption" {
  bucket = aws_s3_bucket.sagemaker-bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
