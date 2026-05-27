variable "environment" {
  description = "Ambiente"
  type        = string
}

variable "eks_cluster_endpoint" {
  description = "Endpoint do cluster EKS"
  type        = string
}

variable "eks_cluster_ca_certificate" {
  description = "CA do cluster EKS"
  type        = string
}

variable "eks_cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
}

variable "argocd_version" {
  description = "Versão do ArgoCD"
  type        = string
  default     = "7.8.1"
}

variable "admin_password" {
  description = "Senha do admin do ArgoCD"
  type        = string
  sensitive   = true
}
