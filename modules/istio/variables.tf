#######################
# Cluster Definitions #
#######################

variable "context" {
  type        = string
  description = "Contexto do cluster (ex: local, dev, prod)"
  default     = "local"
}

#######################
# Istio Variables #
#######################

# --- Istio Base (CRDs) ---

variable "istio_base_release_name" {
  type        = string
  description = "Nome do release Helm do Istio Base (CRDs)"
  default     = "istio-base"
}

variable "istio_base_chart_name" {
  type        = string
  description = "Nome do chart Helm do Istio Base"
  default     = "base"
}

variable "istio_base_chart_version" {
  type        = string
  description = "Versao do chart Helm do Istio Base"
  default     = "1.24.2"
}

# --- Istiod (Control Plane) ---

variable "istiod_release_name" {
  type        = string
  description = "Nome do release Helm do Istiod (Control Plane)"
  default     = "istiod"
}

variable "istiod_chart_name" {
  type        = string
  description = "Nome do chart Helm do Istiod"
  default     = "istiod"
}

variable "istiod_chart_version" {
  type        = string
  description = "Versao do chart Helm do Istiod"
  default     = "1.24.2"
}

# --- Istio Ingress Gateway ---

variable "istio_gateway_release_name" {
  type        = string
  description = "Nome do release Helm do Istio Ingress Gateway"
  default     = "istio-ingressgateway"
}

variable "istio_gateway_chart_name" {
  type        = string
  description = "Nome do chart Helm do Istio Gateway"
  default     = "gateway"
}

variable "istio_gateway_chart_version" {
  type        = string
  description = "Versao do chart Helm do Istio Gateway"
  default     = "1.24.2"
}

# --- Configuracoes Compartilhadas ---

variable "istio_namespace" {
  type        = string
  description = "Namespace onde o Istio sera instalado (istio-system)"
  default     = "istio-system"
}

variable "istio_repository_url" {
  type        = string
  description = "URL do repositorio Helm do Istio"
  default     = "https://istio-release.storage.googleapis.com/charts"
}

variable "istio_mtls_mode" {
  type        = string
  description = "Modo mTLS: PERMISSIVE, STRICT, DISABLE"
  default     = "PERMISSIVE"
}

variable "istio_enable_tracing" {
  type        = bool
  description = "Habilita tracing distribuido (envia spans para Tempo)"
  default     = true
}

variable "istio_tempo_address" {
  type        = string
  description = "Endereco do Tempo para tracing (ex: tempo.monitoring.svc.cluster.local:4317)"
  default     = "tempo.monitoring.svc.cluster.local:4317"
}

variable "istio_ingress_gateway_enabled" {
  type        = bool
  description = "Habilita Istio Ingress Gateway"
  default     = true
}

variable "istio_ingress_gateway_replicas" {
  type        = number
  description = "Numero de replicas do Ingress Gateway"
  default     = 2
}
