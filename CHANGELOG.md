# Changelog

All notable changes to this module are documented here. Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Fixed
- `skills.md`'s "Purpose" line described the module as "Prometheus, Grafana, Loki" with "multi-cluster scrape federation" — neither is accurate. Grepped the module: no standalone Prometheus deployment exists (Mimir is the actual metrics backend, exposed to Grafana as a `prometheus`-type datasource because it speaks the Prometheus remote-write/query API), Tempo and Mimir were both missing from the component list entirely, and there is no scrape-based federation anywhere in the code — workload clusters push telemetry to this stack (Loki push API, Mimir remote-write, Tempo OTLP) via Alloy, not pull/scrape. Rewrote the Purpose section to match `README.md`'s accurate LGTM description.
- `README.md`'s "Provider pins" table said Terraform `= 1.7.5` — `providers.tf` actually pins `= 1.10.5`, matching the platform-wide Terraform 1.10.5 migration already reflected everywhere else. Same stale-version pattern already found and fixed in every other `aj-tf-module-*` repo touched this project.
- `skills.md`'s "Stable ref" pointed at `github.com/ajaylakma/aj-tf-module-observability?ref=observability-01` — wrong org (real org is `ajay-infra`) and a branch that doesn't exist (only `main` — confirmed via `git branch -a`; no tags existed either, despite `README.md`'s own Usage examples already correctly referencing `?ref=v0.1.0`, also nonexistent). Fixed both refs to `v1.0.0` and cut that tag (module was fully implemented with no prior release).
- `skills.md`'s "AWS tags applied" listed `Env`, `Team`, `ManagedBy`, `CostCenter`, `Model`, `Customer` — checked `locals.tf`: the real tag set is `Project`/`ManagedBy`/`Repository`/`Environment`/`Team`/`CostCenter` (from `locals.full_tags`) plus whatever's in `var.tags`. No `Env`, `Model`, or `Customer` tag exists anywhere in this module. Same copy-paste pattern already found in several other modules this project.

## [v1.0.0] - 2026-08-24

Initial release — Grafana LGTM stack (Loki, Mimir, Tempo, Grafana) for the central EKS cluster, with conditional S3/IAM creation to avoid duplicating `aj-infra-central`'s resources. Module was already fully implemented; this tag just formalizes the first stable release so `README.md`/`skills.md` have something real to pin to.
