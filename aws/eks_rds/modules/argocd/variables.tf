variable "environment" {
  type = string
}

variable "eks_cluster_name" {
  type = string
}

variable "argocd_version" {
  type    = string
  default = "7.8.1"
}

variable "eks_cluster_endpoint" {
  type = string
}

variable "eks_cluster_ca_certificate" {
  type = string
}
