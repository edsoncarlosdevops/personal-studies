# ---- Environment Variables ----
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# ---- Workstation Configuration ----
variable "workstation_count" {
  description = "Number of Windows workstations to create"
  type        = number
  default     = 3
}

variable "users_count" {
  description = "Number of AD users to create"
  type        = number
  default     = 10
}

variable "workstation_instance_type" {
  description = "Instance type for workstations"
  type        = string
  default     = "t3.medium"
}
