output "dev_vpc_id" {
  description = "The ID of the VPC created for the dev environment."
  value       = module.infra_dev.vpc_id
}

output "dev_ec2_ip_address" {
  description = "The public IP address of the EC2 instance in the dev environment."
  value       = module.infra_dev.ec2_ip_address
}

