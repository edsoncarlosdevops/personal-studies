###############################
# OpenTelemetry Collector #
###############################

variable "otel_collector_release_name" {
  type        = string
  description = "Nome da release Helm do OpenTelemetry Collector"
}

variable "otel_collector_chart_name" {
  type        = string
  description = "Nome do chart Helm (ex: opentelemetry-collector)"
}

variable "otel_collector_namespace" {
  type        = string
  description = "Namespace onde o Collector será instalado"
}

variable "otel_collector_chart_version" {
  type        = string
  description = "Versão do chart Helm"
}

variable "otel_collector_repository_url" {
  type        = string
  description = "URL do repositório Helm"
}

variable "otel_collector_replica_count" {
  type        = number
  default     = 1
  description = "Número de réplicas do Collector"
}
