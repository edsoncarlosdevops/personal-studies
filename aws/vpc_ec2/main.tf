module "infra_dev" {
    source = "./modules/vpc_ec2"
    environment = "dev"
}