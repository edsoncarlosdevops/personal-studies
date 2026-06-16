variable "resource_group_name" {
  description = "Azure Resource Group name"
  type        = string
  default     = "rg-observability"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus2"
}

variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
  default     = "aks-observability"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.30"
}

variable "node_count" {
  description = "AKS node count"
  type        = number
  default     = 2
}

variable "node_size" {
  description = "AKS node VM size"
  type        = string
  default     = "Standard_B2s"
}
