locals {
  name_prefix = var.name_prefix != "" ? var.name_prefix : "lgtm-${var.environment}"
  is_prod     = var.environment == "prod"

  # S3 bucket names — either created here or passed in from aj-infra-central
  loki_bucket  = var.create_s3_buckets ? aws_s3_bucket.loki[0].bucket : var.loki_bucket
  mimir_bucket = var.create_s3_buckets ? aws_s3_bucket.mimir[0].bucket : var.mimir_bucket
  tempo_bucket = var.create_s3_buckets ? aws_s3_bucket.tempo[0].bucket : var.tempo_bucket

  # IAM role ARN — either created here or passed in from aj-infra-central
  lgtm_role_arn = var.create_iam_role ? aws_iam_role.lgtm[0].arn : var.lgtm_role_arn

  # Loki retention as duration string
  loki_retention = "${var.loki_retention_days * 24}h"

  full_tags = merge({
    Project     = "aj-infra-platform"
    ManagedBy   = "Terraform"
    Repository  = "aj-tf-module-observability"
    Environment = var.environment
    Team        = var.team
    CostCenter  = var.cost_center
  }, var.tags)
}
