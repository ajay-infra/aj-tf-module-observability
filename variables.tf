# ── Core ──────────────────────────────────────────────────────────────────────

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_account_id" {
  type        = string
  description = "AWS account ID — used in IAM policy ARNs."
}

variable "environment" {
  type        = string
  description = "Environment tier: nonprod | prod. Controls replica counts, retention, HA settings."
  validation {
    condition     = contains(["nonprod", "prod"], var.environment)
    error_message = "environment must be 'nonprod' or 'prod'."
  }
}

variable "name_prefix" {
  type        = string
  description = "Prefix for all resource names."
  default     = ""
}

# ── EKS Cluster ───────────────────────────────────────────────────────────────

variable "cluster_name" {
  type        = string
  description = "EKS cluster name — used for Pod Identity associations and aws eks get-token."
}

variable "cluster_endpoint" {
  type        = string
  description = "EKS cluster API server endpoint — used by Helm and Kubernetes providers."
}

variable "cluster_ca_data" {
  type        = string
  description = "EKS cluster CA certificate data (base64-encoded) — used by Helm and Kubernetes providers."
  sensitive   = true
}

# ── S3 Storage ────────────────────────────────────────────────────────────────

variable "create_s3_buckets" {
  type        = bool
  description = <<-EOT
    Create S3 buckets for LGTM storage in this module.
    Set false when aj-infra-central already created the buckets — pass the
    existing bucket names via loki_bucket, mimir_bucket, tempo_bucket variables.
  EOT
  default     = true
}

variable "s3_bucket_prefix" {
  type        = string
  description = "Prefix for S3 bucket names when create_s3_buckets = true."
  default     = ""
}

variable "loki_bucket" {
  type        = string
  description = "Loki S3 bucket name. Required when create_s3_buckets = false."
  default     = ""
}

variable "mimir_bucket" {
  type        = string
  description = "Mimir S3 bucket name. Required when create_s3_buckets = false."
  default     = ""
}

variable "tempo_bucket" {
  type        = string
  description = "Tempo S3 bucket name. Required when create_s3_buckets = false."
  default     = ""
}

# ── IAM ───────────────────────────────────────────────────────────────────────

variable "create_iam_role" {
  type        = bool
  description = <<-EOT
    Create IAM role + Pod Identity association for LGTM S3 access.
    Set false when aj-infra-central already created the role — pass it via lgtm_role_arn.
  EOT
  default     = true
}

variable "lgtm_role_arn" {
  type        = string
  description = "Existing LGTM IAM role ARN. Required when create_iam_role = false."
  default     = ""
}

# ── Grafana ───────────────────────────────────────────────────────────────────

variable "chart_version_grafana" {
  type    = string
  default = "8.8.4"
}

variable "grafana_admin_secret_arn" {
  type        = string
  description = <<-EOT
    Secrets Manager ARN for the Grafana admin password.
    Secret must contain key: password
    If empty, a random password is generated and stored in Secrets Manager.
  EOT
  default     = ""
}

variable "grafana_domain" {
  type        = string
  description = "Domain for Grafana ingress (e.g. grafana.central-nonprod.platform.internal). Leave empty to skip Ingress."
  default     = ""
}

variable "grafana_github_org" {
  type        = string
  description = "GitHub org for Grafana OAuth (e.g. 'ajay-infra'). Leave empty to use admin password auth."
  default     = ""
}

# ── Loki ──────────────────────────────────────────────────────────────────────

variable "chart_version_loki" {
  type    = string
  default = "6.24.0"
}

variable "loki_retention_days" {
  type        = number
  description = "Log retention in days."
  default     = 30
}

# ── Mimir ─────────────────────────────────────────────────────────────────────

variable "chart_version_mimir" {
  type    = string
  default = "5.5.1"
}

variable "mimir_retention_days" {
  type        = number
  description = "Metrics retention in days."
  default     = 90
}

# ── Tempo ─────────────────────────────────────────────────────────────────────

variable "chart_version_tempo" {
  type    = string
  default = "1.14.0"
}

variable "tempo_retention_days" {
  type        = number
  description = "Trace retention in days."
  default     = 14
}

# ── Tags ──────────────────────────────────────────────────────────────────────

variable "team" {
  type    = string
  default = "infra-core"
}

variable "cost_center" {
  type    = string
  default = "infra-2026-q1"
}

variable "tags" {
  type    = map(string)
  default = {}
}
