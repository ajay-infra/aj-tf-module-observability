# nonprod.tfvars — central-nonprod cluster LGTM stack

aws_account_id = "REPLACE_WITH_ACCOUNT_ID"
aws_region     = "us-east-1"
environment    = "nonprod"

# From aj-infra-release provision-central.yml outputs
cluster_name     = "central-nonprod-blue"
cluster_endpoint = "REPLACE_WITH_CLUSTER_ENDPOINT"
cluster_ca_data  = "REPLACE_WITH_CLUSTER_CA"

# aj-infra-central already created S3 buckets + IAM role — use those
create_s3_buckets = false
create_iam_role   = false

# Bucket names from aj-infra-central outputs
loki_bucket  = "central-nonprod-loki-chunks"
mimir_bucket = "central-nonprod-mimir-blocks"
tempo_bucket = "central-nonprod-tempo-traces"

# IAM role ARN from aj-infra-central outputs
lgtm_role_arn = "REPLACE_WITH_LGTM_ROLE_ARN"

chart_version_grafana = "8.8.4"
chart_version_loki    = "6.24.0"
chart_version_mimir   = "5.5.1"
chart_version_tempo   = "1.14.0"

grafana_domain     = "grafana.central-nonprod.platform.internal"
grafana_github_org = "ajay-infra"

loki_retention_days  = 30
mimir_retention_days = 90
tempo_retention_days = 14

team        = "infra-core"
cost_center = "infra-2026-q1"
