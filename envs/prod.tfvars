# prod.tfvars — central-prod cluster LGTM stack (HA replicas, longer retention)

aws_account_id = "REPLACE_WITH_ACCOUNT_ID"
aws_region     = "us-east-1"
environment    = "prod"

cluster_name     = "central-prod-blue"
cluster_endpoint = "REPLACE_WITH_CLUSTER_ENDPOINT"
cluster_ca_data  = "REPLACE_WITH_CLUSTER_CA"

create_s3_buckets = false
create_iam_role   = false

loki_bucket  = "central-prod-loki-chunks"
mimir_bucket = "central-prod-mimir-blocks"
tempo_bucket = "central-prod-tempo-traces"

lgtm_role_arn = "REPLACE_WITH_LGTM_ROLE_ARN"

chart_version_grafana = "8.8.4"
chart_version_loki    = "6.24.0"
chart_version_mimir   = "5.5.1"
chart_version_tempo   = "1.14.0"

grafana_domain     = "grafana.central-prod.platform.internal"
grafana_github_org = "ajay-infra"

loki_retention_days  = 90
mimir_retention_days = 365
tempo_retention_days = 30

team        = "infra-core"
cost_center = "infra-2026-q1"
