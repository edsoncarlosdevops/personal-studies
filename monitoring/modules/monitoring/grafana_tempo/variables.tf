variable "tempo_release_name" {
  type        = string
  description = "Nome da release Helm do Grafana Tempo"
}

variable "tempo_chart_name" {
  type        = string
  description = "Nome do chart Helm (ex: tempo)"
}

variable "tempo_namespace" {
  type        = string
  description = "Namespace onde o Tempo será instalado"
}

variable "tempo_chart_version" {
  type        = string
  description = "Versão do chart Helm"
}

variable "tempo_repository_url" {
  type        = string
  description = "URL do repositório Helm"
}