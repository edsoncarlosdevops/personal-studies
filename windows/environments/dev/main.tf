# ---- VPC ----
module "vpc" {
  source = "../../modules/vpc"

  environment = "dev"
}

# ---- My public IP (dynamic) ----
data "http" "my_ip" {
  url = "https://api.ipify.org"
}

# ---- S3 ----
module "s3" {
  source = "../../modules/s3"

  environment = "dev"
  bucket_name = "windows-ad-scripts-${module.vpc.vpc_id}"
}

# ---- Security Group ----
module "security_group" {
  source = "../../modules/security-group"

  environment      = "dev"
  vpc_id           = module.vpc.vpc_id
  allowed_rdp_cidr = "${chomp(data.http.my_ip.response_body)}/32"
}

# ---- Windows Server ----

# Auto-generate secure local Administrator password (sensitive output)
resource "random_password" "admin" {
  length           = 16
  special          = true
  override_special = "!_#-"
  min_special      = 2
}

# Auto-generate Directory Services Restore Mode (DSRM) safe mode password for Active Directory promotion
resource "random_password" "safe_mode" {
  length           = 16
  special          = true
  override_special = "!_#-"
  min_special      = 2
}

# Generate unique suffix for SSH key pairs to avoid collisions
resource "random_string" "key_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Programmatically generate key pair for initial EC2 Windows Administrator password retrieval if needed
resource "tls_private_key" "windows_admin" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "windows_admin" {
  key_name   = "windows-ad-${random_string.key_suffix.result}"
  public_key = tls_private_key.windows_admin.public_key_openssh
}

# Save generated private key locally with restrictive file permissions (read-only for owner)
resource "local_file" "windows_admin_pem" {
  content         = tls_private_key.windows_admin.private_key_pem
  filename        = "${path.module}/windows-ad-key.pem"
  file_permission = "0600"
}

module "windows_server" {
  source = "../../modules/windows-server"

  environment           = "dev"
  subnet_id             = module.vpc.public_subnet_id
  security_group_id     = module.security_group.security_group_id
  admin_password        = random_password.admin.result
  safe_mode_password    = random_password.safe_mode.result
  instance_type         = "t3.large"
  key_name              = aws_key_pair.windows_admin.key_name
  is_domain_controller  = true
  hostname              = "DC-01"
}

# ---- Windows Workstations (count-based) ----
module "windows_workstation" {
  source = "../../modules/windows-server"
  count  = var.workstation_count

  environment           = "dev"
  subnet_id             = module.vpc.public_subnet_id
  security_group_id     = module.security_group.security_group_id
  admin_password        = random_password.admin.result
  safe_mode_password    = random_password.safe_mode.result
  instance_type         = var.workstation_instance_type
  key_name              = aws_key_pair.windows_admin.key_name
  hostname              = "WORKSTATION-${format("%02d", count.index + 1)}"
  is_domain_controller  = false
}

# ---- Generate Ansible Inventory Automatically ----
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    workstation_ips = module.windows_workstation[*].public_ip
    admin_password  = random_password.admin.result
  })
  filename = "${path.root}/../../ansible/inventory/dev.yml"
}
