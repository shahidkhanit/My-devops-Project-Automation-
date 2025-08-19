resource "aws_s3_bucket" "mimir_storage" {
  bucket = "mimir-metrics-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket_versioning" "mimir_versioning" {
  bucket = aws_s3_bucket.mimir_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "mimir_encryption" {
  bucket = aws_s3_bucket.mimir_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# IAM role for Mimir
resource "aws_iam_role" "mimir_role" {
  name = "mimir-storage-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = module.devops_cluster.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${replace(module.devops_cluster.cluster_oidc_issuer_url, "https://", "")}:sub": "system:serviceaccount:monitoring:mimir"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "mimir_s3_policy" {
  name = "mimir-s3-policy"
  role = aws_iam_role.mimir_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.mimir_storage.arn,
          "${aws_s3_bucket.mimir_storage.arn}/*"
        ]
      }
    ]
  })
}