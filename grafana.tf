# ── Grafana Admin Password ────────────────────────────────────────────────────

resource "random_password" "grafana_admin" {
  count   = var.grafana_admin_secret_arn == "" ? 1 : 0
  length  = 24
  special = false
}

resource "aws_secretsmanager_secret" "grafana_admin" {
  count = var.grafana_admin_secret_arn == "" ? 1 : 0

  name                    = "${local.name_prefix}/grafana/admin-password"
  description             = "Grafana admin password for ${local.name_prefix}"
  recovery_window_in_days = local.is_prod ? 30 : 0

  tags = local.full_tags
}

resource "aws_secretsmanager_secret_version" "grafana_admin" {
  count = var.grafana_admin_secret_arn == "" ? 1 : 0

  secret_id     = aws_secretsmanager_secret.grafana_admin[0].id
  secret_string = jsonencode({ password = random_password.grafana_admin[0].result })
}

locals {
  grafana_admin_secret_arn = var.grafana_admin_secret_arn != "" ? var.grafana_admin_secret_arn : (
    length(aws_secretsmanager_secret.grafana_admin) > 0 ? aws_secretsmanager_secret.grafana_admin[0].arn : ""
  )
}

# ── Grafana Helm Release ──────────────────────────────────────────────────────

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name   = "monitoring"
    labels = { "app.kubernetes.io/managed-by" = "Terraform" }
  }
}

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = var.chart_version_grafana
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  wait    = true
  timeout = 300

  values = [
    yamlencode({
      replicas = local.is_prod ? 2 : 1

      podDisruptionBudget = {
        enabled      = local.is_prod
        minAvailable = 1
      }

      # Admin credentials from Secrets Manager via env var
      admin = {
        existingSecret = "grafana-admin-secret"
        userKey        = "username"
        passwordKey    = "password"
      }

      # Grafana Ingress (only when grafana_domain is set)
      ingress = {
        enabled = var.grafana_domain != ""
        annotations = {
          "kubernetes.io/ingress.class"               = "alb"
          "alb.ingress.kubernetes.io/scheme"          = "internal"
          "alb.ingress.kubernetes.io/target-type"     = "ip"
          "alb.ingress.kubernetes.io/certificate-arn" = "" # set via cert-manager annotation
        }
        hosts = var.grafana_domain != "" ? [var.grafana_domain] : []
        tls   = var.grafana_domain != "" ? [{ hosts = [var.grafana_domain], secretName = "grafana-tls" }] : []
      }

      # Data sources — pre-wired to Loki, Mimir, Tempo in the same cluster
      datasources = {
        "datasources.yaml" = {
          apiVersion = 1
          datasources = [
            {
              name      = "Mimir"
              type      = "prometheus"
              url       = "http://mimir-nginx.monitoring.svc.cluster.local/prometheus"
              isDefault = true
              access    = "proxy"
              jsonData = {
                httpMethod     = "POST"
                prometheusType = "Mimir"
              }
            },
            {
              name   = "Loki"
              type   = "loki"
              url    = "http://loki-gateway.monitoring.svc.cluster.local"
              access = "proxy"
            },
            {
              name   = "Tempo"
              type   = "tempo"
              url    = "http://tempo.monitoring.svc.cluster.local:3100"
              access = "proxy"
              jsonData = {
                tracesToLogsV2 = {
                  datasourceUid = "loki"
                }
                serviceMap = {
                  datasourceUid = "prometheus"
                }
              }
            },
          ]
        }
      }

      # Pre-provisioned dashboards
      dashboardProviders = {
        "dashboardproviders.yaml" = {
          apiVersion = 1
          providers = [{
            name            = "default"
            orgId           = 1
            folder          = ""
            type            = "file"
            disableDeletion = false
            editable        = true
            options         = { path = "/var/lib/grafana/dashboards/default" }
          }]
        }
      }

      dashboards = {
        default = {
          kubernetes-cluster = {
            gnetId     = 7249
            revision   = 1
            datasource = "Mimir"
          }
          node-exporter = {
            gnetId     = 1860
            revision   = 37
            datasource = "Mimir"
          }
          cilium-agent = {
            gnetId     = 16611
            revision   = 1
            datasource = "Mimir"
          }
        }
      }

      resources = {
        requests = { cpu = "100m", memory = "256Mi" }
        limits   = { cpu = "500m", memory = "512Mi" }
      }

      # GitHub OAuth (when github_org is provided)
      grafana_ini = var.grafana_github_org != "" ? {
        auth = {
          oauth_auto_login = true
        }
        "auth.github" = {
          enabled       = true
          allow_sign_up = true
          org_name      = var.grafana_github_org
          scopes        = "user:email,read:org"
        }
        server = {
          root_url = "https://${var.grafana_domain}"
        }
      } : {}
    })
  ]

  depends_on = [kubernetes_namespace.monitoring]
}
