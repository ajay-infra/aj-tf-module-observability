# skills.md — aj-tf-module-observability

## Purpose
Provisions the Grafana LGTM stack (Loki, Mimir, Tempo, Grafana) on the central EKS
cluster, plus supporting AWS resources (S3 for long-term storage, Pod Identity IAM
role — both conditional, since `aj-infra-central` can create them instead). There is
no standalone Prometheus deployment — Mimir is the Prometheus-remote-write-compatible
metrics backend, exposed to Grafana as a `prometheus`-type datasource. There is no
scrape-based federation: workload-cluster Alloy agents push logs/metrics/traces to
this stack (Loki push API, Mimir remote-write, Tempo OTLP) over VPC peering.

## Type
`tf-module`

## Stable ref
```
source = "github.com/ajay-infra/aj-tf-module-observability?ref=v1.0.0"
```

## Key inputs
| Variable | Description |
|---|---|
| `environment` | dev \| staging \| uat \| prod |
| `name_prefix` | Resource name prefix |
| `cluster_name` | Target EKS cluster name |
| `cluster_endpoint` | EKS API endpoint |
| `cluster_ca_data` | EKS CA certificate |
| `create_s3_buckets` | Create S3 buckets for Loki/Thanos |

## AWS tags applied
`Project`, `ManagedBy`, `Repository`, `Environment`, `Team`, `CostCenter` (set in
`locals.full_tags`), plus whatever's in `var.tags`. No `Env`, `Model`, or `Customer`
tag exists in this module.

## Depends on
`aj-tf-module-eks` — requires cluster_name, cluster_endpoint, cluster_ca_data

## Branching convention
- `main` — active development
- semver tags (`v1.0.0`, ...) — stable pinned releases, per `README.md` usage examples

## CI checks
fmt, validate, plan (dry-run), tfsec/checkov

## Agentic capabilities
- Detect missing ServiceMonitor for a new workload
- Alert on S3 bucket missing lifecycle policy (cold storage costs)
- Generate PR to add Grafana dashboard for onboarded service
- Validate Loki retention matches env policy (prod 30d hot, then S3/Glacier)
