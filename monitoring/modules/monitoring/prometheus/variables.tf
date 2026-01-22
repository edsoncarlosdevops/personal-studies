#######################
# Cluster Definitions #
#######################

variable "context" {
  type        = string
  description = "Contexto do cluster (ex: local)"
  default     = "local"
}

#########################
# Kube Prometheus Stack #
#########################

variable "prometheus_release_name" {
  type = string
}

variable "prometheus_chart_name" {
  type = string
}

variable "prometheus_namespace" {
  type = string
}

variable "prometheus_chart_version" {
  type = string
}

variable "prometheus_repository_url" {
  type = string
}

# Variáveis Dummy do Istio (para compatibilidade futura ou manter padrão)
variable "prometheus_vs_name" {
  type    = string
  default = "ignore"
}

variable "prometheus_vs_dns" {
  type    = string
  default = "localhost"
}

variable "prometheus_vs_port" {
  type    = number
  default = 80
}

variable "prometheus_replica_count" {
  type        = number
  default     = 1
  description = "Number of Prometheus replicas"
}