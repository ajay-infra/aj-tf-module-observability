# CLAUDE.md — aj-tf-module-observability

> Local context file for Claude Code. Not pushed to GitHub.

## What This Module Does

Grafana LGTM stack (Loki/Mimir/Tempo/Grafana) deployed on the central EKS cluster.
Reusable module — consumed by aj-infra-central (or used standalone).

## Module Structure

```
storage.tf   → S3 buckets (conditional), IAM role + Pod Identity (conditional)
grafana.tf   → kubernetes_namespace, random_password, Secrets Manager, helm_release.grafana
lgtm.tf      → helm_release.loki, helm_release.mimir, helm_release.tempo
locals.tf    → name_prefix, is_prod, loki/mimir/tempo bucket names, lgtm_role_arn
variables.tf → environment, cluster_*, create_s3_buckets, create_iam_role, retention vars
outputs.tf   → loki_push_endpoint, mimir_remote_write_endpoint, tempo_otlp_endpoint, grafana_url
providers.tf → aws + helm + kubernetes + random
```

## Key Design Decisions

- **create_s3_buckets = false when aj-infra-central created buckets** — avoids duplication
- **environment variable drives ALL scaling** — is_prod local controls replicas, PDBs, retention
- **Loki: SingleBinary (nonprod) / SimpleScalable (prod)** — set via deploymentMode
- **Mimir distributed** — 1 replica each (nonprod), 2-3 replicas + PDBs (prod)
- **Grafana data sources auto-wired** — Loki, Mimir, Tempo configured by default
- **Grafana admin password generated** — random_password + Secrets Manager; no hardcoded creds
- **CI: fmt+validate+security only** — Helm/K8s providers require real cluster for plan

## S3 Bucket Names Convention

aj-infra-central creates:  central-nonprod-loki-chunks, -mimir-blocks, -tempo-traces
Module-created:            <s3_bucket_prefix><name_prefix>-loki-chunks, etc.

## Known TODOs

- [ ] Fill in cluster_endpoint + cluster_ca_data in envs/*.tfvars after cluster is up
- [ ] Add grafana_admin_secret_arn once Secrets Manager secret is pre-created
- [ ] Tune Mimir ingester memory limits based on actual metrics volume
- [ ] Wire Grafana GitHub OAuth (client ID + secret) once OAuth App exists
- [ ] Add Alloy chart for receiving OTLP from app pods (if not covered by k8s-monitoring)
