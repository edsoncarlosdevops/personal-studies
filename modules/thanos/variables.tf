#######################
# Cluster Definitions #
#######################

variable "context" {
  type        = string
  description = "Contexto do cluster (ex: local, dev, prod)"
  default     = "local"
}

########################
# Thanos Variables #
########################

variable "thanos_release_name" {
  type        = string
  description = "Nome do release Helm do Thanos"
  default     = "thanos"
}

variable "thanos_chart_name" {
  type        = string
  description = "Nome do chart Helm do Thanos"
  default     = "thanos"
}

variable "thanos_namespace" {
  type        = string
  description = "Namespace onde o Thanos sera instalado"
  default     = "thanos"
}

variable "thanos_chart_version" {
  type        = string
  description = "Versao do chart Helm do Thanos"
  default     = "15.13.1"
}

variable "thanos_repository_url" {
  type        = string
  description = "URL do repositorio Helm do Thanos"
  default     = "https://charts.bitnami.com/bitnami"
}

variable "thanos_store_enabled" {
  type        = bool
  description = "Habilita o componente Store (le dados historicos do object storage)"
  default     = true
}

variable "thanos_compactor_enabled" {
  type        = bool
  description = "Habilita o componente Compactor (compacta e aplica retencao)"
  default     = true
}

variable "thanos_query_enabled" {
  type        = bool
  description = "Habilita o componente Query (ponto unico de consulta)"
  default     = true
}

variable "thanos_query_replicas" {
  type        = number
  description = "Numero de replicas do Thanos Query"
  default     = 2
}

variable "thanos_objstore_type" {
  type        = string
  description = "Tipo de object storage: s3, gcs, azure, minio"
  default     = "s3"
}

variable "thanos_objstore_bucket" {
  type        = string
  description = "Nome do bucket no object storage"
  default     = "thanos-data"
}

variable "thanos_objstore_endpoint" {
  type        = string
  description = "Endpoint do object storage (ex: s3.us-east-1.amazonaws.com)"
  default     = "s3.us-east-1.amazonaws.com"
}

variable "thanos_retention_raw" {
  type        = string
  description = "Tempo de retencao de dados brutos (raw)"
  default     = "30d"
}

variable "thanos_retention_5m" {
  type        = string
  description = "Tempo de retencao de dados downsampled 5m"
  default     = "90d"
}

variable "thanos_retention_1h" {
  type        = string
  description = "Tempo de retencao de dados downsampled 1h"
  default     = "365d"
}
