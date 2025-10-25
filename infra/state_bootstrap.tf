#############################################
# Remote state storage (S3 + DynamoDB lock)
# Run locally once to create these.
#############################################

# S3 bucket for Terraform state
resource "aws_s3_bucket" "tf_state" {
  bucket = "cloud-resume-tfstate-446050219344" # must be globally unique
  lifecycle { prevent_destroy = true }
  tags = local.tags
}

# Enable bucket encryption & block public access (good hygiene)
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state_enc" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state_block" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "tf_lock" {
  name         = "cloud-resume-tflock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = local.tags
}

# Friendly outputs so you can copy/paste into backend config next
output "tf_state_bucket" {
  value = aws_s3_bucket.tf_state.bucket
}

output "tf_lock_table" {
  value = aws_dynamodb_table.tf_lock.name
}
