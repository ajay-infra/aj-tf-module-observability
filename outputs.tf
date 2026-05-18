# ── S3 Buckets ────────────────────────────────────────────────────────────────

output "loki_bucket" {
  description = "Loki S3 bucket name."
  value       = local.loki_bucket
}

output "mimir_bucket" {
  description = "Mimir S3 bucket name."
  value       = local.mimir_bucket
}

output "tempo_bucket" {
  description = "Tempo S3 bucket name."
  value       = local.tempo_bucket
}

output "lgtm_role_arn" {
  description = "IAM role ARN used by Loki, Mimir, Tempo pods for S3 access."
  value       = local.lgtm_role_arn
}

# ── Push Endpoints ────────────────────────────────────────────────────────────
# Use these in aj-infra-platform (Alloy config) for workload cluster telemetry push.

output "loki_push_endpoint" {
  description = "Loki log push endpoint — used by Alloy on workload clusters."
  value       = "http://loki-gateway.${helm_release.loki.namespace}.svc.cluster.local/loki/api/v1/push"
}

output "mimir_remote_write_endpoint" {
  description = "Mimir metrics remote-write endpoint — used by Alloy on workload clusters."
  value       = "http://mimir-nginx.${helm_release.mimir.namespace}.svc.cluster.local/api/v1/push"
}

output "tempo_otlp_endpoint" {
  description = "Tempo OTLP gRPC endpoint — used by Alloy on workload clusters."
  value       = "http://tempo.${helm_release.tempo.namespace}.svc.cluster.local:4317"
}

# ── Grafana ───────────────────────────────────────────────────────────────────

output "grafana_url" {
  description = "Grafana UI URL (empty when grafana_domain is not set)."
  value       = var.grafana_domain != "" ? "https://${var.grafana_domain}" : ""
}

output "grafana_admin_secret_arn" {
  description = "Secrets Manager ARN for Grafana admin credentials."
  value       = local.grafana_admin_secret_arn
}
