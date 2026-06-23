#######################
# Cluster Definitions #
#######################

variable "context" {
  type        = string
  description = "Contexto do cluster (ex: local, dev, prod)"
  default     = "local"
}

#######################
# Vault Variables #
#######################

variable "vault_release_name" {
  type        = string
  description = "Nome do release Helm do Vault"
  default     = "vault"
}

variable "vault_chart_name" {
  type        = string
  description = "Nome do chart Helm do Vault"
  default     = "vault"
}

variable "vault_namespace" {
  type        = string
  description = "Namespace onde o Vault sera instalado"
  default     = "vault"
}

variable "vault_chart_version" {
  type        = string
  description = "Versao do chart Helm do Vault"
  default     = "0.29.1"
}

variable "vault_repository_url" {
  type        = string
  description = "URL do repositorio Helm do Vault"
  default     = "https://helm.releases.hashicorp.com"
}

variable "vault_mode" {
  type        = string
  description = "Modo de operacao do Vault: standalone, ha, dev"
  default     = "standalone"
}

variable "vault_replica_count" {
  type        = number
  description = "Numero de replicas do Vault (apenas modo HA)"
  default     = 1
}

variable "vault_ui_enabled" {
  type        = bool
  description = "Habilita interface web do Vault"
  default     = true
}

variable "vault_persistence_enabled" {
  type        = bool
  description = "Habilita persistencia para dados do Vault"
  default     = true
}

variable "vault_persistence_size" {
  type        = string
  description = "Tamanho do volume persistente do Vault"
  default     = "10Gi"
}
