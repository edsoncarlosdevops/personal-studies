variable "release_name" {
  description = "Helm release name"
  type        = string
  default     = "postgres-exporter"
}

variable "chart_version" {
  description = "Chart version"
  type        = string
  default     = "6.0.0"
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "monitoring"
}

variable "db_host" {
  description = "PostgreSQL host"
  type        = string
}

variable "db_user" {
  description = "PostgreSQL user"
  type        = string
}

variable "db_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "observability"
}
