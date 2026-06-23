#######################
# Cluster Definitions #
#######################

variable "context" {
  type        = string
  description = "Contexto do cluster (ex: local, dev, prod)"
  default     = "local"
}

########################
# Keycloak Variables #
########################

variable "keycloak_release_name" {
  type        = string
  description = "Nome do release Helm do Keycloak"
  default     = "keycloak"
}

variable "keycloak_chart_name" {
  type        = string
  description = "Nome do chart Helm do Keycloak"
  default     = "keycloak"
}

variable "keycloak_namespace" {
  type        = string
  description = "Namespace onde o Keycloak sera instalado"
  default     = "keycloak"
}

variable "keycloak_chart_version" {
  type        = string
  description = "Versao do chart Helm do Keycloak"
  default     = "21.4.4"
}

variable "keycloak_repository_url" {
  type        = string
  description = "URL do repositorio Helm do Keycloak"
  default     = "https://charts.bitnami.com/bitnami"
}

variable "keycloak_replica_count" {
  type        = number
  description = "Numero de replicas do Keycloak"
  default     = 2
}

variable "keycloak_admin_user" {
  type        = string
  description = "Usuario administrador do Keycloak"
  default     = "admin"
}

variable "keycloak_admin_password" {
  type        = string
  description = "Senha do administrador do Keycloak"
  default     = "admin"
  sensitive   = true
}

variable "keycloak_postgresql_enabled" {
  type        = bool
  description = "Habilita PostgreSQL interno do Keycloak"
  default     = true
}

variable "keycloak_postgresql_password" {
  type        = string
  description = "Senha do PostgreSQL interno do Keycloak"
  default     = "keycloak"
  sensitive   = true
}
