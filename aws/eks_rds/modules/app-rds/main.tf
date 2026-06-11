resource "kubernetes_namespace" "app" {
  metadata {
    name = "app-${var.environment}"

    labels = {
      name           = "app-${var.environment}"
      environment    = var.environment
      managed-by     = "terraform"
      app            = "app-rds"
    }
  }
}

resource "kubernetes_config_map" "app" {
  metadata {
    name      = "app-rds-config"
    namespace = kubernetes_namespace.app.metadata[0].name

    labels = {
      app         = "app-rds"
      environment = var.environment
    }
  }

  data = {
    DB_HOST  = var.db_endpoint
    DB_PORT  = tostring(var.db_port)
    DB_NAME  = var.db_name
    DB_USER  = var.db_username
    NODE_ENV = var.environment
  }
}

resource "kubernetes_secret" "app" {
  metadata {
    name      = "app-rds-secret"
    namespace = kubernetes_namespace.app.metadata[0].name

    labels = {
      app         = "app-rds"
      environment = var.environment
    }
  }

  data = {
    DB_PASSWORD = var.db_password
  }
}

resource "kubernetes_deployment" "app" {
  metadata {
    name      = "app-rds"
    namespace = kubernetes_namespace.app.metadata[0].name

    labels = {
      app         = "app-rds"
      environment = var.environment
    }
  }

  spec {
    replicas = var.app_replicas

    selector {
      match_labels = {
        app = "app-rds"
      }
    }

    template {
      metadata {
        labels = {
          app         = "app-rds"
          environment = var.environment
        }

        annotations = {
          # OTEL Operator injeta auto-instrumentacao automaticamente
          "instrumentation.opentelemetry.io/inject-nodejs" = "true"
        }
      }

      spec {
        container {
          name  = "app-rds"
          image = var.app_image
          image_pull_policy = "Always"

          port {
            container_port = 3000
            name           = "http"
            protocol       = "TCP"
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.app.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.app.metadata[0].name
            }
          }

          resources {
            limits = {
              cpu    = "250m"
              memory = "256Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 3000
            }
            initial_delay_seconds = 15
            period_seconds        = 20
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 3000
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app" {
  metadata {
    name      = "app-rds"
    namespace = kubernetes_namespace.app.metadata[0].name

    labels = {
      app         = "app-rds"
      environment = var.environment
    }
  }

  spec {
    selector = {
      app = "app-rds"
    }

    port {
      name        = "http"
      port        = 3000
      target_port = 3000
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

