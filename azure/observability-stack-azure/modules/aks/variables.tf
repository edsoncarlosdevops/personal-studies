# ── Resource Group ──
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

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default = {
    Environment = "dev"
    ManagedBy   = "terraform"
    Project     = "observability-stack-azure"
  }
}

# ── Networking ──
variable "vnet_name" {
  description = "Virtual Network name"
  type        = string
  default     = "vnet-observability"
}

variable "vnet_address_space" {
  description = "VNet address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aks_subnet_name" {
  description = "AKS nodes subnet name"
  type        = string
  default     = "snet-aks"
}

variable "aks_subnet_prefixes" {
  description = "AKS subnet address prefixes"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

# PostgreSQL and Private Endpoints removed
# (eastus2 region does not support PostgreSQL in this subscription)

variable "allowed_api_source_ips" {
  description = "Source IPs allowed to reach AKS API server"
  type        = list(string)
  default     = []
}

# ── AKS Cluster ──
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
  description = "Number of nodes"
  type        = number
  default     = 2
}

variable "max_node_count" {
  description = "Max nodes for auto-scaling"
  type        = number
  default     = 5
}

variable "node_size" {
  description = "VM size for nodes"
  type        = string
  default     = "Standard_B2s"
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 60
}

variable "enable_auto_scaling" {
  description = "Enable cluster auto-scaling"
  type        = bool
  default     = false
}
