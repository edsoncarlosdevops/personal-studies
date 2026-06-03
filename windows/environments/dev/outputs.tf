# ---- Domain Controller ----
output "dc_instance_id" {
  description = "Domain Controller EC2 instance ID"
  value       = module.windows_server.instance_id
}

output "dc_public_ip" {
  description = "Domain Controller public IP for RDP"
  value       = module.windows_server.public_ip
}

output "dc_private_ip" {
  description = "Domain Controller private IP"
  value       = module.windows_server.private_ip
}

output "rdp_command" {
  description = "RDP connection command for DC"
  value       = "mstsc /v:${module.windows_server.public_ip}"
}

output "username" {
  description = "Administrator username for RDP login"
  value       = "${"."}\\Administrator"
}

output "admin_password" {
  description = "Administrator password. Run: terraform output admin_password"
  value       = random_password.admin.result
  sensitive   = true
}

output "safe_mode_password" {
  description = "DSRM Safe Mode password for AD recovery. Run: terraform output safe_mode_password"
  value       = random_password.safe_mode.result
  sensitive   = true
}

# ---- Workstations ----
output "workstation_ips" {
  description = "Public IPs of all Windows workstations"
  value       = module.windows_workstation[*].public_ip
}

output "workstation_private_ips" {
  description = "Private IPs of all Windows workstations"
  value       = module.windows_workstation[*].private_ip
}

output "workstation_names" {
  description = "Hostnames of all Windows workstations"
  value       = [for i in range(length(module.windows_workstation)) : "WORKSTATION-${format("%02d", i + 1)}"]
}

# ---- Ansible Inventory ----
output "ansible_inventory" {
  description = "Ansible inventory YAML content. Run: terraform output -raw ansible_inventory > ../ansible/inventory/dev.yml"
  value = templatefile("${path.module}/templates/inventory.tpl", {
    workstation_ips = module.windows_workstation[*].public_ip
  })
}

# ---- Others ----
output "s3_bucket" {
  description = "S3 bucket name"
  value       = module.s3.bucket_id
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "workstation_count" {
  description = "Number of workstations provisioned"
  value       = length(module.windows_workstation)
}

output "users_count" {
  description = "Number of AD users created"
  value       = var.users_count
}

# ---- Lab Users ----
output "lab_users" {
  description = "List of AD users created in the lab"
  value = [
    for i in range(var.users_count) : {
      username        = "user${i + 1}@lab.local"
      sam_account     = "user${i + 1}"
      display_name    = "User ${i + 1}"
      password        = "P@ssw0rd123!"
      ou              = "OU=LabUsers,DC=lab,DC=local"
      groups          = ["Domain Users", "Remote Desktop Users"]
    }
  ]
}

