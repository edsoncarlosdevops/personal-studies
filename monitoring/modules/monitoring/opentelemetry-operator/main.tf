########
# Helm #
########

resource "helm_release" "opentelemetry_operator" {
  name             = var.otel_operator_release_name
  chart            = var.otel_operator_chart_name
  create_namespace = true
  wait             = true
  namespace        = var.otel_operator_namespace
  version          = var.otel_operator_chart_version
  repository       = var.otel_operator_repository_url
  force_update     = true
  cleanup_on_fail  = true
  upgrade_install  = true

  values = [
    templatefile("${path.module}/config/values.yaml", {
      otel_operator_replica_count = var.otel_operator_replica_count
    })
  ]
}

##############################
# Auto-instrumentation       #
##############################
# Cria o recurso Instrumentation que configura o Operator para injetar
# automaticamente o SDK OTel nos pods com as annotations:
#   instrumentation.opentelemetry.io/inject-python: "true"
#   instrumentation.opentelemetry.io/inject-nodejs: "true"
#   instrumentation.opentelemetry.io/inject-java: "true"
#
# O endpoint aponta para o Collector centralizado (monitoring namespace)

resource "kubernetes_manifest" "instrumentation_python" {
  manifest = {
    apiVersion = "opentelemetry.io/v1alpha1"
    kind       = "Instrumentation"
    metadata = {
      name      = "python-instrumentation"
      namespace = var.otel_operator_namespace
    }
    spec = {
      exporter = {
        endpoint = "http://opentelemetry-collector.${var.otel_operator_namespace}.svc.cluster.local:4318"
      }
      propagators = ["tracecontext", "baggage"]
      sampler = {
        type     = "parentbased_traceidratio"
        argument = "1"
      }
    }
  }
}

resource "kubernetes_manifest" "instrumentation_nodejs" {
  manifest = {
    apiVersion = "opentelemetry.io/v1alpha1"
    kind       = "Instrumentation"
    metadata = {
      name      = "nodejs-instrumentation"
      namespace = var.otel_operator_namespace
    }
    spec = {
      exporter = {
        endpoint = "http://opentelemetry-collector.${var.otel_operator_namespace}.svc.cluster.local:4318"
      }
      propagators = ["tracecontext", "baggage"]
      sampler = {
        type     = "parentbased_traceidratio"
        argument = "1"
      }
    }
  }
}

