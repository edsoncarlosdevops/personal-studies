#######################
# Cluster Definitions #
#######################

variable "context" {
  type        = string
  description = "Contexto do cluster (ex: local, dev, prod)"
  default     = "local"
}

###################
# Redis Variables #
###################

variable "redis_release_name" {
  type        = string
  description = "Nome do release Helm do Redis"
  default     = "redis"
}

variable "redis_chart_name" {
  type        = string
  description = "Nome do chart Helm do Redis"
  default     = "redis"
}

variable "redis_namespace" {
  type        = string
  description = "Namespace onde o Redis sera instalado"
  default     = "redis"
}

variable "redis_chart_version" {
  type        = string
  description = "Versao do chart Helm do Redis"
  default     = "20.11.3"
}

variable "redis_repository_url" {
  type        = string
  description = "URL do repositorio Helm do Redis"
  default     = "https://charts.bitnami.com/bitnami"
}

variable "redis_replica_count" {
  type        = number
  description = "Numero de replicas do Redis"
  default     = 1
}

variable "redis_auth_enabled" {
  type        = bool
  description = "Habilita autenticacao por senha no Redis"
  default     = true
}

variable "redis_persistence_enabled" {
  type        = bool
  description = "Habilita persistencia em disco (RDB/AOF)"
  default     = true
}

variable "redis_persistence_size" {
  type        = string
  description = "Tamanho do volume persistente do Redis"
  default     = "8Gi"
}

variable "redis_architecture" {
  type        = string
  description = "Arquitetura do Redis: standalone, replication, sentinel"
  default     = "standalone"
}
