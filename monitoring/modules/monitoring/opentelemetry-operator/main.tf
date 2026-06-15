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
# Cria o recurso Instrumentation via local-exec (kubectl apply) APOS
# o Helm instalar o Operator e seus CRDs. Usar kubernetes_manifest
# causa erro no plan pois o CRD opentelemetry.io/v1alpha1 ainda
# nao existe (só e criado pelo Helm).
#
# Estas annotations habilitam auto-instrumentacao via Operator:
#   instrumentation.opentelemetry.io/inject-python: "true"
#   instrumentation.opentelemetry.io/inject-nodejs: "true"
#
# O endpoint aponta para o Collector centralizado (monitoring namespace)

resource "null_resource" "instrumentation_resources" {
  depends_on = [helm_release.opentelemetry_operator]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      echo "Aguardando CRD Instrumentation ficar disponivel..."
      for i in $(seq 1 30); do
        if kubectl get crd instrumentations.opentelemetry.io &>/dev/null; then
          echo "  ✅ CRD Instrumentation disponivel!"
          break
        fi
        echo "  [$i/30] Aguardando CRD..."
        sleep 5
      done

      echo "Criando recurso Instrumentation (Python)..."
      cat <<'YAML' | kubectl apply -f -
apiVersion: opentelemetry.io/v1alpha1
kind: Instrumentation
metadata:
  name: python-instrumentation
  namespace: ${var.otel_operator_namespace}
spec:
  exporter:
    endpoint: http://opentelemetry-collector.${var.otel_operator_namespace}.svc.cluster.local:4318
  propagators: ["tracecontext", "baggage"]
  sampler:
    type: parentbased_traceidratio
    argument: "1"
YAML

      echo "Criando recurso Instrumentation (Node.js)..."
      cat <<'YAML' | kubectl apply -f -
apiVersion: opentelemetry.io/v1alpha1
kind: Instrumentation
metadata:
  name: nodejs-instrumentation
  namespace: ${var.otel_operator_namespace}
spec:
  exporter:
    endpoint: http://opentelemetry-collector.${var.otel_operator_namespace}.svc.cluster.local:4318
  propagators: ["tracecontext", "baggage"]
  sampler:
    type: parentbased_traceidratio
    argument: "1"
YAML

      echo "  ✅ Instrumentation resources criados com sucesso!"
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Instrumentation resources removidos manualmente se necessario: kubectl delete instrumentation -n monitoring --all'"
  }
}

