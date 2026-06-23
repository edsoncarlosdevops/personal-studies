# ═══════════════════════════════════════════════════════════
# Istio - Instalacao em 3 etapas
# ═══════════════════════════════════════════════════════════
# O Istio e dividido em 3 charts Helm para permitir
# atualizacoes independentes:
#
# 1. istio-base:   CRDs (Custom Resource Definitions)
# 2. istiod:       Control Plane
# 3. gateway:      Ingress Gateway (opcional)
#
# Ordem de instalacao:
#   base → istiod → gateway (se habilitado)
#
# Ordem de remocao (inversa):
#   gateway → istiod → base (CUIDADO: remove todos os CRDs)
# ═══════════════════════════════════════════════════════════

########
# Helm #
########

# --- 1. Istio Base (CRDs) ---
# Instala os Custom Resource Definitions do Istio:
# VirtualService, DestinationRule, Gateway, ServiceEntry,
# AuthorizationPolicy, PeerAuthentication, etc.
#
# NOTA: Este chart NAO deve ser atualizado junto com os outros.
# CRDs sao globais e podem afetar outros componentes.

resource "helm_release" "istio_base" {
  name             = var.istio_base_release_name
  chart            = var.istio_base_chart_name
  create_namespace = true
  wait             = false
  timeout          = 300
  namespace        = var.istio_namespace
  version          = var.istio_base_chart_version
  repository       = var.istio_repository_url
  force_update     = true
  upgrade_install  = true
  cleanup_on_fail  = true
}

# --- 2. Istiod (Control Plane) ---
# istiod e o cerebro do Istio. Ele:
# - Gerencia a configuracao de todos os proxies Envoy
# - Distribui certificados mTLS
# - Processa VirtualService, DestinationRule, etc.
#
# Valores sao passados via template do config/values.yaml

resource "helm_release" "istiod" {
  name             = var.istiod_release_name
  chart            = var.istiod_chart_name
  create_namespace = false
  wait             = false
  timeout          = 600
  namespace        = var.istio_namespace
  version          = var.istiod_chart_version
  repository       = var.istio_repository_url
  force_update     = true
  upgrade_install  = true
  atomic           = true
  cleanup_on_fail  = true

  values = [
    templatefile("${path.module}/config/values.yaml", {
      istio_mtls_mode      = var.istio_mtls_mode
      istio_enable_tracing = var.istio_enable_tracing
      istio_tempo_address  = var.istio_tempo_address
    })
  ]

  depends_on = [helm_release.istio_base]
}

# --- 3. Istio Ingress Gateway (opcional) ---
# Proxy Envoy na borda do cluster.
# Substitui o Nginx Ingress Controller com beneficios:
# - mTLS ate o ingress
# - Canary deployment
# - Circuit breaker
#
# Se NAO for usar o Istio Ingress Gateway, mantenha o Nginx Ingress.

resource "helm_release" "istio_ingress_gateway" {
  count            = var.istio_ingress_gateway_enabled ? 1 : 0
  name             = var.istio_gateway_release_name
  chart            = var.istio_gateway_chart_name
  create_namespace = false
  wait             = false
  timeout          = 600
  namespace        = var.istio_namespace
  version          = var.istio_gateway_chart_version
  repository       = var.istio_repository_url
  force_update     = true
  upgrade_install  = true
  atomic           = true
  cleanup_on_fail  = true

  values = [
    yamlencode({
      service = {
        type = "LoadBalancer"
        ports = [
          { port = 80, targetPort = 8080, name = "http" },
          { port = 443, targetPort = 8443, name = "https" },
        ]
      }
      replicas = var.istio_ingress_gateway_replicas
    })
  ]

  depends_on = [helm_release.istiod]
}
