variable "opencost_release_name" { type = string }
variable "opencost_chart_name" { type = string }
variable "opencost_namespace" { type = string }
variable "opencost_chart_version" { type = string }
variable "opencost_repository_url" { type = string }

variable "opencost_prometheus_address" {
  description = "Endereco interno do Prometheus para o OpenCost consultar"
  type        = string
}

variable "opencost_cluster_id" {
  description = "ID do cluster para identificar nos relatorios"
  type        = string
  default     = "orbstack-local"
}

variable "opencost_resources_preset" {
  type    = string
  default = "small"
}

variable "opencost_replica_count" {
  type    = number
  default = 1
}

# =====================================================================
# VARIAVEIS DE PRECIFICACAO - AZURE
# =====================================================================
# Configure estas variaveis para o OpenCost consultar precos reais
# da Azure Retail Rates API automaticamente.
#
# Para criar um Service Principal:
#   az ad sp create-for-rbac \
#     --name "opencost-pricing" \
#     --role "Reader" \
#     --scope "/subscriptions/<SUBSCRIPTION_ID>"
#
# Para registrar o provider de precos (se necessario):
#   az provider register --namespace Microsoft.Pricing
# =====================================================================

variable "opencost_azure_enabled" {
  description = "Habilitar integracao com Azure Retail Rates API para precos automaticos"
  type        = bool
  default     = false
}

variable "opencost_azure_subscription_id" {
  description = "Subscription ID do Azure (ex: 00000000-0000-0000-0000-000000000000)"
  type        = string
  default     = ""
}

variable "opencost_azure_client_id" {
  description = "Client ID (appId) do Service Principal do Azure"
  type        = string
  default     = ""
}

variable "opencost_azure_tenant_id" {
  description = "Tenant ID do Azure"
  type        = string
  default     = ""
}

variable "opencost_azure_client_secret" {
  description = "Client Secret (password) do Service Principal do Azure"
  type        = string
  default     = ""
  sensitive   = true
}
