locals {
  resource_location = "West Europe"
  virtual_network = {
    name             = "appp-network"
    address_prefixes = ["10.0.0.0/16"]
  }
  subnet_address_prefix = ["10.0.0.0/24", "10.0.1.0/24"]
  subnets = [
    {
      name             = "websubnet01"
      address_prefixes = ["10.0.0.0/24"]
    },
    {
      name             = "appsubnet01"
      address_prefixes = ["10.0.1.0/24"]
    }
  ]
}