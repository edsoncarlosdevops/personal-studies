variable "opencost_release_name" { type = string }
variable "opencost_chart_name" { type = string }
variable "opencost_namespace" { type = string }
variable "opencost_chart_version" { type = string }
variable "opencost_repository_url" { type = string }

variable "opencost_prometheus_address" {
  description = "Endereço interno do Prometheus para o OpenCost consultar"
  type        = string
}

variable "opencost_cluster_id" {
  description = "ID do cluster para identificar nos relatórios"
  type        = string
  default     = "orbstack-local"
}

variable "opencost_resources_preset" {
  type    = string
  default = "small" # Default pequeno para rodar leve no Mac
}

variable "opencost_replica_count" {
  type    = number
  default = 1
}