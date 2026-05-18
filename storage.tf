# ── S3 Storage (optional — skip when aj-infra-central already created buckets) ─

resource "aws_s3_bucket" "loki" {
  count = var.create_s3_buckets ? 1 : 0

  bucket        = "${var.s3_bucket_prefix}${local.name_prefix}-loki-chunks"
  force_destroy = !local.is_prod

  tags = merge(local.full_tags, { Component = "loki" })
}

resource "aws_s3_bucket" "mimir" {
  count = var.create_s3_buckets ? 1 : 0

  bucket        = "${var.s3_bucket_prefix}${local.name_prefix}-mimir-blocks"
  force_destroy = !local.is_prod

  tags = merge(local.full_tags, { Component = "mimir" })
}

resource "aws_s3_bucket" "tempo" {
  count = var.create_s3_buckets ? 1 : 0

  bucket        = "${var.s3_bucket_prefix}${local.name_prefix}-tempo-traces"
  force_destroy = !local.is_prod

  tags = merge(local.full_tags, { Component = "tempo" })
}

locals {
  all_buckets = compact([
    var.create_s3_buckets ? aws_s3_bucket.loki[0].bucket : "",
    var.create_s3_buckets ? aws_s3_bucket.mimir[0].bucket : "",
    var.create_s3_buckets ? aws_s3_bucket.tempo[0].bucket : "",
    !var.create_s3_buckets ? var.loki_bucket : "",
    !var.create_s3_buckets ? var.mimir_bucket : "",
    !var.create_s3_buckets ? var.tempo_bucket : "",
  ])
}

resource "aws_s3_bucket_server_side_encryption_configuration" "loki" {
  count  = var.create_s3_buckets ? 1 : 0
  bucket = aws_s3_bucket.loki[0].id

  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "mimir" {
  count  = var.create_s3_buckets ? 1 : 0
  bucket = aws_s3_bucket.mimir[0].id

  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tempo" {
  count  = var.create_s3_buckets ? 1 : 0
  bucket = aws_s3_bucket.tempo[0].id

  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "loki" {
  count  = var.create_s3_buckets ? 1 : 0
  bucket = aws_s3_bucket.loki[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "mimir" {
  count  = var.create_s3_buckets ? 1 : 0
  bucket = aws_s3_bucket.mimir[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "tempo" {
  count  = var.create_s3_buckets ? 1 : 0
  bucket = aws_s3_bucket.tempo[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── IAM — Pod Identity for LGTM S3 access ────────────────────────────────────

resource "aws_iam_policy" "lgtm_s3" {
  count = var.create_iam_role ? 1 : 0

  name        = "${local.name_prefix}-lgtm-s3"
  description = "Loki, Mimir, Tempo — S3 read/write for LGTM storage backends"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "LGTMBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
        ]
        Resource = [
          "arn:aws:s3:::${local.loki_bucket}",
          "arn:aws:s3:::${local.loki_bucket}/*",
          "arn:aws:s3:::${local.mimir_bucket}",
          "arn:aws:s3:::${local.mimir_bucket}/*",
          "arn:aws:s3:::${local.tempo_bucket}",
          "arn:aws:s3:::${local.tempo_bucket}/*",
        ]
      },
    ]
  })

  tags = local.full_tags
}

resource "aws_iam_role" "lgtm" {
  count = var.create_iam_role ? 1 : 0

  name = "${local.name_prefix}-lgtm"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })

  tags = local.full_tags
}

resource "aws_iam_role_policy_attachment" "lgtm_s3" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.lgtm[0].name
  policy_arn = aws_iam_policy.lgtm_s3[0].arn
}

resource "aws_eks_pod_identity_association" "lgtm" {
  count = var.create_iam_role ? 1 : 0

  cluster_name    = var.cluster_name
  namespace       = "monitoring"
  service_account = "lgtm-storage"
  role_arn        = aws_iam_role.lgtm[0].arn
}
