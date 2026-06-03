variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the EC2 instance will be created"
  type        = string
}

variable "security_group_id" {
  description = "Security Group ID"
  type        = string
}

variable "admin_password" {
  description = "Windows Administrator password"
  type        = string
  sensitive   = true
}

variable "safe_mode_password" {
  description = "Safe Mode Recovery password for Active Directory"
  type        = string
  sensitive   = true
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.large"
}

variable "key_name" {
  description = "Key pair name for EC2 access"
  type        = string
  default     = null
}

variable "hostname" {
  description = "Custom hostname for the Windows instance"
  type        = string
  default     = null
}


variable "is_domain_controller" {
  description = "Whether this instance is the Domain Controller (installs AD DS) or a workstation"
  type        = bool
  default     = false
}
