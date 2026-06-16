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

variable "storage_account_name" {
  description = "Storage Account name (globally unique, 3-24 chars, lowercase letters + numbers)"
  type        = string
}

variable "container_name" {
  description = "Blob container name for .tfstate files"
  type        = string
  default     = "terraform-state"
}
