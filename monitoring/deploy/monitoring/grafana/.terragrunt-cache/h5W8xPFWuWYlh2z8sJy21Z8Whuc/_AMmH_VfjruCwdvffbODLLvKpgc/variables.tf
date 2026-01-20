#######################
# Cluster Definitions #
#######################

variable "context" {
  type = string
}

###########
# Grafana #
###########

variable "grafana_release_name" {
  type = string
}

variable "grafana_chart_name" {
  type = string
}

variable "grafana_namespace" {
  type = string
}

variable "grafana_chart_version" {
  type = string
}

variable "grafana_repository_url" {
  type = string
}

variable "grafana_vs_name" {
  type = string
}

variable "grafana_vs_dns" {
  type = string
}

variable "grafana_vs_port" {
  type = number
}

variable "grafana_replica_count" {
  type        = number
  default     = 1
  description = "Number of Grafana replicas"
}
