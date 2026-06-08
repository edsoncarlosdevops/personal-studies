variable "loki_release_name" { type = string }
variable "loki_chart_name" { type = string }
variable "loki_namespace" { type = string }
variable "loki_chart_version" { type = string }
variable "loki_repository_url" { type = string }
# Demais variáveis podem ser removidas se não usadas no main.tf