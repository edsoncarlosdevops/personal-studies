variable "resource_group_name" {
  description = "Resource Group name for Terraform state"
  type        = string
  default     = "terraform-states"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus2"
}

variable "storage_account_prefix" {
  description = "Prefix for storage account name (will append random suffix)"
  type        = string
  default     = "tfstate"
}

variable "container_name" {
  description = "Blob container name for .tfstate files"
  type        = string
  default     = "terraform-state"
}
