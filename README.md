# aj-tf-module-observability

Terraform module for the Grafana LGTM stack — Loki (logs), Mimir (metrics), Tempo (traces), Grafana (dashboards). Deployed on the central EKS clusters that act as the observability hub for all workload clusters.

---

## What this module does

| Component | Chart | Purpose |
|---|---|---|
| **Loki** | `grafana/loki` | Log aggregation — receives logs from Alloy on workload clusters |
| **Mimir** | `grafana/mimir-distributed` | Long-term metrics storage (Prometheus-compatible remote write) |
| **Tempo** | `grafana/tempo` | Distributed tracing — receives OTLP traces from Alloy |
| **Grafana** | `grafana/grafana` | Unified dashboard — auto-wired to Loki, Mimir, Tempo |

All four are deployed to the `monitoring` namespace on the central cluster. Workload cluster Alloy agents push telemetry to the central cluster via VPC peering.

---

## Relationship with aj-infra-central

`aj-infra-central` creates S3 buckets + Pod Identity IAM role for LGTM storage. This module consumes those as inputs (`create_s3_buckets = false`, `create_iam_role = false`, `lgtm_role_arn = "..."`) to avoid creating duplicate resources.

Alternatively, this module can create its own S3 + IAM when used standalone (`create_s3_buckets = true`).

---

## Environment profiles

| Setting | nonprod | prod |
|---|---|---|
| Loki mode | SingleBinary (1 pod) | SimpleScalable (2+2+2 pods) |
| Mimir | 1 replica each | 2-3 replicas + PDBs |
| Grafana replicas | 1 | 2 + PDB |
| Log retention | 30 days | 90 days |
| Metrics retention | 90 days | 365 days |
| Trace retention | 14 days | 30 days |

Controlled by `environment = "nonprod" | "prod"` — all scaling and retention flow from this one variable.

---

## Usage with aj-infra-central

```hcl
# aj-infra-central already created S3 + IAM — pass them in
module "lgtm" {
  source = "github.com/ajay-infra/aj-tf-module-observability?ref=v0.1.0"

  aws_account_id   = "123456789012"
  environment      = "nonprod"
  cluster_name     = "central-nonprod-blue"
  cluster_endpoint = data.aws_eks_cluster.central.endpoint
  cluster_ca_data  = data.aws_eks_cluster.central.certificate_authority[0].data

  # Use existing S3 + IAM from aj-infra-central
  create_s3_buckets = false
  create_iam_role   = false
  loki_bucket       = "central-nonprod-loki-chunks"
  mimir_bucket      = "central-nonprod-mimir-blocks"
  tempo_bucket      = "central-nonprod-tempo-traces"
  lgtm_role_arn     = "arn:aws:iam::123456789012:role/central-nonprod-lgtm"

  grafana_domain    = "grafana.central-nonprod.platform.internal"
  grafana_github_org = "ajay-infra"

  loki_retention_days  = 30
  mimir_retention_days = 90
  tempo_retention_days = 14
}
```

### Standalone (creates its own S3 + IAM)

```hcl
module "lgtm" {
  source = "github.com/ajay-infra/aj-tf-module-observability?ref=v0.1.0"

  aws_account_id   = "123456789012"
  environment      = "nonprod"
  cluster_name     = "my-cluster"
  cluster_endpoint = "https://..."
  cluster_ca_data  = "..."

  create_s3_buckets = true
  create_iam_role   = true
  s3_bucket_prefix  = "myproduct-"
}
```

---

## Workload cluster endpoints (outputs)

After deployment, pass these to `aj-infra-platform` so Alloy on workload clusters can push telemetry:

```hcl
loki_endpoint         = module.lgtm.loki_push_endpoint
mimir_endpoint        = module.lgtm.mimir_remote_write_endpoint
tempo_endpoint        = module.lgtm.tempo_otlp_endpoint
```

---

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `aws_account_id` | yes | — | AWS account ID |
| `environment` | yes | — | `nonprod` or `prod` — controls all HA/retention settings |
| `cluster_name` | yes | — | EKS cluster name |
| `cluster_endpoint` | yes | — | EKS API server endpoint |
| `cluster_ca_data` | yes | — | EKS CA certificate (base64) |
| `create_s3_buckets` | no | `true` | Create S3 buckets in this module |
| `create_iam_role` | no | `true` | Create Pod Identity IAM role in this module |
| `loki_bucket` | if !create | — | Loki S3 bucket name |
| `mimir_bucket` | if !create | — | Mimir S3 bucket name |
| `tempo_bucket` | if !create | — | Tempo S3 bucket name |
| `lgtm_role_arn` | if !create | — | Existing LGTM Pod Identity role ARN |
| `grafana_domain` | no | `""` | Grafana Ingress domain |
| `grafana_github_org` | no | `""` | GitHub org for Grafana OAuth |
| `loki_retention_days` | no | `30` | Log retention |
| `mimir_retention_days` | no | `90` | Metrics retention |
| `tempo_retention_days` | no | `14` | Trace retention |

---

## Outputs

| Output | Description |
|---|---|
| `loki_push_endpoint` | Loki HTTP push URL for Alloy |
| `mimir_remote_write_endpoint` | Mimir Prometheus remote-write URL |
| `tempo_otlp_endpoint` | Tempo OTLP gRPC endpoint |
| `grafana_url` | Grafana UI URL |
| `grafana_admin_secret_arn` | Secrets Manager ARN for admin credentials |
| `lgtm_role_arn` | IAM role ARN for S3 access |
| `loki_bucket` / `mimir_bucket` / `tempo_bucket` | S3 bucket names |

---

## Provider pins

| Tool | Version |
|---|---|
| Terraform | `= 1.7.5` |
| AWS | `= 5.100.0` |
| Helm | `= 2.12.1` |
| Kubernetes | `= 2.27.0` |
| random | `= 3.6.3` |
