variable "resource_group_name" {
  description = "Azure Resource Group name"
  type        = string
}

variable "server_name" {
  description = "PostgreSQL server name"
  type        = string
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "observability"
}

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "16"
}

variable "admin_user" {
  description = "Admin username"
  type        = string
  sensitive   = true
}

variable "admin_password" {
  description = "Admin password"
  type        = string
  sensitive   = true
}

variable "sku_name" {
  description = "SKU name (e.g. B_Standard_B1ms, GP_Standard_D2s_v3)"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "storage_mb" {
  description = "Storage in MB"
  type        = number
  default     = 32768
}

variable "subnet_name" {
  description = "Subnet name for private endpoint"
  type        = string
}

variable "vnet_name" {
  description = "VNet name"
  type        = string
}

variable "ha_enabled" {
  description = "Enable high availability"
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Backup retention days"
  type        = number
  default     = 7
}

variable "geo_redundant_backup" {
  description = "Enable geo-redundant backup"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Project   = "observability-stack-azure"
  }
}
