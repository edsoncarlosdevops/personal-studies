########
# Helm #
########

locals {
  resource_presets = {
    small = {
      requests = { cpu = "50m", memory = "64Mi" }
      limits   = { cpu = "200m", memory = "256Mi" }
    }
    medium = {
      requests = { cpu = "100m", memory = "128Mi" }
      limits   = { cpu = "500m", memory = "512Mi" }
    }
  }

  opencost_resources = local.resource_presets[var.opencost_resources_preset]
}

resource "helm_release" "opencost" {
  name             = var.opencost_release_name
  chart            = var.opencost_chart_name
  create_namespace = true
  wait             = false
  namespace        = var.opencost_namespace
  version          = var.opencost_chart_version
  repository       = var.opencost_repository_url
  force_update     = true
  cleanup_on_fail  = true
  upgrade_install  = true

  values = [
    templatefile("${path.module}/config/values.yaml", {
      opencost_cluster_id    = var.opencost_cluster_id
      opencost_resources     = jsonencode(local.opencost_resources)
    })
  ]

  # ====================================================================
  # CONFIGURACAO DE PRECOS
  # ====================================================================
  # As env vars abaixo sao passadas diretamente ao pod do OpenCost
  # para que ele consiga calcular os custos corretamente.
  #
  # AZURE (descomente se tiver as credenciais):
  #   Preencha as 4 variaveis opencost_azure_* no terragrunt.hcl
  #   e descomente o bloco dynamic "set" abaixo.
  #
  # AWS:  Nao requer configuracao via Helm. O OpenCost detecta
  #       automaticamente quando roda em EKS e usa a AWS Pricing API
  #       com as credenciais IAM do node. Apenas garanta as permissoes:
  #       - AmazonEC2ReadOnlyAccess
  #       - AWSPriceListServiceFullAccess
  #
  # GCP:  Nao requer configuracao via Helm. O OpenCost detecta
  #       automaticamente quando roda em GKE e usa a Google Cloud
  #       Billing API com a Service Account do node.
  #       Escopo necessario:
  #       - https://www.googleapis.com/auth/cloud-platform
  # ====================================================================

  # --- AZURE PRICING (via Service Principal) ---
  # Descomente o bloco abaixo e preencha as credenciais no terragrunt
  # dynamic "set" {
  #   for_each = var.opencost_azure_enabled ? [1] : []
  #   content {
  #     name  = "opencost.extraEnv[0].name"
  #     value = "AZURE_SUBSCRIPTION_ID"
  #   }
  #   content {
  #     name  = "opencost.extraEnv[0].value"
  #     value = var.opencost_azure_subscription_id
  #   }
  #   # ... repetir para CLIENT_ID, TENANT_ID, CLIENT_SECRET
  # }

  # --- CUSTOM PRICING (fallback para on-prem/local) ---
  # Descomente para ambientes sem cloud provider:
  # set {
  #   name  = "opencost.exporter.extraEnv[0].name"
  #   value = "CPU_COST_PER_HOUR"
  # }
  # set {
  #   name  = "opencost.exporter.extraEnv[0].value"
  #   value = "0.031611"
  # }
  # set {
  #   name  = "opencost.exporter.extraEnv[1].name"
  #   value = "RAM_COST_PER_GB_HOUR"
  # }
  # set {
  #   name  = "opencost.exporter.extraEnv[1].value"
  #   value = "0.004237"
  # }
}
