###############################
# OpenTelemetry Operator #
###############################

variable "otel_operator_release_name" {
  type        = string
  description = "Nome da release Helm do OpenTelemetry Operator"
}

variable "otel_operator_chart_name" {
  type        = string
  description = "Nome do chart Helm (ex: opentelemetry-operator)"
}

variable "otel_operator_namespace" {
  type        = string
  description = "Namespace onde o Operator será instalado"
}

variable "otel_operator_chart_version" {
  type        = string
  description = "Versão do chart Helm"
}

variable "otel_operator_repository_url" {
  type        = string
  description = "URL do repositório Helm"
}

variable "otel_operator_replica_count" {
  type        = number
  default     = 1
  description = "Número de réplicas do Operator"
}
