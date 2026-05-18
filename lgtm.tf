# ── Loki ──────────────────────────────────────────────────────────────────────
# nonprod: SingleBinary (1 pod, simpler)
# prod:    SimpleScalable (separate read/write/backend pods)

resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = var.chart_version_loki
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  wait    = true
  timeout = 600

  values = [
    yamlencode({
      deploymentMode = local.is_prod ? "SimpleScalable" : "SingleBinary"

      loki = {
        auth_enabled = false

        commonConfig = {
          replication_factor = local.is_prod ? 2 : 1
        }

        storage = {
          bucketNames = {
            chunks = local.loki_bucket
            ruler  = local.loki_bucket
            admin  = local.loki_bucket
          }
          type = "s3"
          s3 = {
            region   = var.aws_region
            insecure = false
          }
        }

        schemaConfig = {
          configs = [{
            from         = "2024-01-01"
            store        = "tsdb"
            object_store = "s3"
            schema       = "v13"
            index = {
              prefix = "loki_index_"
              period = "24h"
            }
          }]
        }

        limits_config = {
          retention_period            = local.loki_retention
          ingestion_rate_mb           = local.is_prod ? 32 : 16
          ingestion_burst_size_mb     = local.is_prod ? 64 : 32
          max_query_parallelism       = local.is_prod ? 16 : 8
          max_entries_limit_per_query = 50000
        }
      }

      # SingleBinary (nonprod)
      singleBinary = {
        replicas = local.is_prod ? 0 : 1
        resources = {
          requests = { cpu = "200m", memory = "512Mi" }
          limits   = { cpu = "1000m", memory = "2Gi" }
        }
      }

      # SimpleScalable (prod)
      read = {
        replicas            = local.is_prod ? 2 : 0
        podDisruptionBudget = { maxUnavailable = 1 }
      }
      write = {
        replicas            = local.is_prod ? 2 : 0
        podDisruptionBudget = { maxUnavailable = 1 }
      }
      backend = {
        replicas            = local.is_prod ? 2 : 0
        podDisruptionBudget = { maxUnavailable = 1 }
      }

      gateway = {
        enabled  = true
        replicas = local.is_prod ? 2 : 1
      }

      serviceAccount = {
        create = true
        name   = "lgtm-storage"
        annotations = {
          "eks.amazonaws.com/role-arn" = local.lgtm_role_arn
        }
      }

      monitoring = {
        serviceMonitor = { enabled = true }
        selfMonitoring = { enabled = false }
        lokiCanary     = { enabled = false }
      }
    })
  ]

  depends_on = [kubernetes_namespace.monitoring]
}

# ── Mimir ──────────────────────────────────────────────────────────────────────
# nonprod: single-binary
# prod:    read-write microservices (distributed)

resource "helm_release" "mimir" {
  name       = "mimir"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "mimir-distributed"
  version    = var.chart_version_mimir
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  wait    = true
  timeout = 600

  values = [
    yamlencode({
      mimir = {
        structuredConfig = {
          common = {
            storage = {
              backend = "s3"
              s3 = {
                bucket_name = local.mimir_bucket
                region      = var.aws_region
              }
            }
          }
          limits = {
            # Metrics retention
            compactor_blocks_retention_period = "${var.mimir_retention_days}d"
          }
        }
      }

      # nonprod: single replica of each component
      # prod: 2+ replicas with PDBs
      distributor = {
        replicas            = local.is_prod ? 2 : 1
        podDisruptionBudget = local.is_prod ? { maxUnavailable = 1 } : {}
        resources = {
          requests = { cpu = "100m", memory = "256Mi" }
          limits   = { cpu = "500m", memory = "1Gi" }
        }
      }

      ingester = {
        replicas             = local.is_prod ? 3 : 1
        podDisruptionBudget  = local.is_prod ? { maxUnavailable = 1 } : {}
        zoneAwareReplication = { enabled = false }
        resources = {
          requests = { cpu = "200m", memory = "512Mi" }
          limits   = { cpu = "1000m", memory = "2Gi" }
        }
      }

      querier = {
        replicas            = local.is_prod ? 2 : 1
        podDisruptionBudget = local.is_prod ? { maxUnavailable = 1 } : {}
      }

      query_frontend = {
        replicas            = local.is_prod ? 2 : 1
        podDisruptionBudget = local.is_prod ? { maxUnavailable = 1 } : {}
      }

      store_gateway = {
        replicas             = local.is_prod ? 2 : 1
        podDisruptionBudget  = local.is_prod ? { maxUnavailable = 1 } : {}
        zoneAwareReplication = { enabled = false }
      }

      compactor = {
        replicas = 1
      }

      nginx = {
        enabled  = true
        replicas = local.is_prod ? 2 : 1
      }

      serviceAccount = {
        create = true
        name   = "lgtm-storage"
        annotations = {
          "eks.amazonaws.com/role-arn" = local.lgtm_role_arn
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace.monitoring]
}

# ── Tempo ──────────────────────────────────────────────────────────────────────
# Single binary in both nonprod and prod at this scale

resource "helm_release" "tempo" {
  name       = "tempo"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "tempo"
  version    = var.chart_version_tempo
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  wait    = true
  timeout = 300

  values = [
    yamlencode({
      tempo = {
        storage = {
          trace = {
            backend = "s3"
            s3 = {
              bucket   = local.tempo_bucket
              endpoint = "s3.${var.aws_region}.amazonaws.com"
              region   = var.aws_region
              insecure = false
            }
          }
        }

        retention = "${var.tempo_retention_days}h"

        metricsGenerator = {
          enabled = true
          remoteWrite = [{
            url = "http://mimir-nginx.monitoring.svc.cluster.local/api/v1/push"
          }]
        }
      }

      serviceAccount = {
        create = true
        name   = "lgtm-storage"
        annotations = {
          "eks.amazonaws.com/role-arn" = local.lgtm_role_arn
        }
      }

      resources = {
        requests = { cpu = "100m", memory = "256Mi" }
        limits   = { cpu = "500m", memory = "1Gi" }
      }
    })
  ]

  depends_on = [kubernetes_namespace.monitoring]
}
