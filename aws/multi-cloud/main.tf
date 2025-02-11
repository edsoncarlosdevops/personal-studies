module "aws_instance" {
  source         = "./modules/aws_instance"
  ami            = "ami-0c02fb55956c7d316"
  instance_type  = "t2.micro"
  instance_name  = "prod-instance"
}

module "azure_resource_group" {
  source              = "./modules/azure_resource_group"
  resource_group_name = "prod-group"
  location            = "East US"
}

