###############################
# Promtail #
###############################

variable "promtail_release_name" {
  type        = string
  description = "Nome da release Helm do Promtail"
  default     = "promtail"
}

variable "promtail_chart_name" {
  type        = string
  description = "Nome do chart Helm do Promtail"
  default     = "promtail"
}

variable "promtail_namespace" {
  type        = string
  description = "Namespace onde o Promtail sera instalado"
  default     = "monitoring"
}

variable "promtail_chart_version" {
  type        = string
  description = "Versao do chart Helm do Promtail"
  default     = "6.16.6"
}

variable "promtail_repository_url" {
  type        = string
  description = "URL do repositorio Helm do Promtail"
  default     = "https://grafana.github.io/helm-charts"
}

variable "promtail_loki_endpoint" {
  type        = string
  description = "Endpoint do Loki para envio dos logs"
  default     = "http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push"
}
