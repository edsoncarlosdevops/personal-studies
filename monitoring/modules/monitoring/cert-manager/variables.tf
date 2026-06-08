variable "cert_manager_release_name" {
  type        = string
  description = "Nome da release Helm do cert-manager"
}

variable "cert_manager_chart_name" {
  type        = string
  description = "Nome do chart Helm (ex: cert-manager)"
}

variable "cert_manager_namespace" {
  type        = string
  description = "Namespace onde o cert-manager será instalado"
}

variable "cert_manager_chart_version" {
  type        = string
  description = "Versão do chart Helm"
}

variable "cert_manager_repository_url" {
  type        = string
  description = "URL do repositório Helm"
}
