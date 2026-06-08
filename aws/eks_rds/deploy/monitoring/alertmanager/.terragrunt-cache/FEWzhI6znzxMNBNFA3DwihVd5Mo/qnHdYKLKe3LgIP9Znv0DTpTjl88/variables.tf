variable "alertmanager_release_name" {
  type        = string
  description = "Nome da release Helm do Alertmanager"
}

variable "alertmanager_chart_name" {
  type        = string
  description = "Nome do chart Helm (ex: alertmanager)"
}

variable "alertmanager_namespace" {
  type        = string
  description = "Namespace onde o Alertmanager será instalado"
}

variable "alertmanager_chart_version" {
  type        = string
  description = "Versão do chart Helm"
}

variable "alertmanager_repository_url" {
  type        = string
  description = "URL do repositório Helm"
}