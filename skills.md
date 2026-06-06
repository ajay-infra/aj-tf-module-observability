# skills.md — aj-tf-module-observability

## Purpose
Provisions the observability stack for an EKS cluster: Prometheus, Grafana, Loki, and supporting AWS resources (S3 for long-term storage, IAM roles). Supports multi-cluster scrape federation.

## Type
`tf-module`

## Stable ref
```
source = "github.com/ajaylakma/aj-tf-module-observability?ref=observability-01"
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
`Env`, `Team`, `ManagedBy`, `CostCenter`, `Model`, `Customer`

## Depends on
`aj-tf-module-eks` — requires cluster_name, cluster_endpoint, cluster_ca_data

## Branching convention
- `main` — active development
- `observability-01` — stable pinned release

## CI checks
fmt, validate, plan (dry-run), tfsec/checkov

## Agentic capabilities
- Detect missing ServiceMonitor for a new workload
- Alert on S3 bucket missing lifecycle policy (cold storage costs)
- Generate PR to add Grafana dashboard for onboarded service
- Validate Loki retention matches env policy (prod 30d hot, then S3/Glacier)
