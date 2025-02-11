# Multi-Cloud Project

## About the Project

This project demonstrates the concept of modularization in Terraform, which allows you to organize and reuse configurations for managing infrastructure across multiple cloud providers, such as AWS and Azure.

Modularization encapsulates complex logic into reusable blocks, called modules, making the code easier to maintain, scale, and share. In this project:
- We create an EC2 instance in AWS.
- We create a resource group in Azure.
- We use modules to separate logic and efficiently manage multiple providers.


## Benefits of Modularization

1.  Code Reusability:
	- A module can be reused in different parts of the project (e.g., production, staging, testing) or in other projects.
2.	Organization:
	- Related resources are grouped, making the project easier to read and maintain.
3.	Scalability:
	- Adding new resources or environments only requires changes to the main configuration.
4.	Collaboration:
	- Modules can be shared across teams, promoting consistent standards.

---

## Requirements

- ***Terraform CLI:*** Install the latest version of Terraform.
- ***Access Credentials:***
	- AWS: Configure your credentials using `~/.aws/credentials` or environment variables `(AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY)`.
	- Azure: Authenticate using az login via Azure CLI.


## Project Structure

```
multi-cloud/
├── main.tf               
├── variables.tf          # (Optional) Declares global variables.
└── modules/
    ├── aws_instance/
    │   ├── main.tf       
    │   ├── variables.tf  
    │   └── outputs.tf    
    ├── azure_resource_group/
        ├── main.tf       
        ├── variables.tf  
        └── outputs.tf    
```

---


### Module Configurations

***AWS Module: aws_instance***
- Creates an EC2 instance in AWS.
- Customizable:
- AMI ID.
- Instance type.
- Instance name (tag).

***Azure Module: azure_resource_group***
- Creates a resource group in Azure.
- Customizable:
	- Resource group name.
	- Location (region).

---

### Module Configurations: main.tf

***Provider Declarations***

```
provider "aws" {
  region = "us-east-1"
}

provider "azurerm" {
  features {}
}
```

***Invoking the Modules***

```
module "aws_instance" {
  source         = "./modules/aws_instance"
  ami            = "ami-0abcdef1234567890"
  instance_type  = "t2.micro"
  instance_name  = "prod-instance"
}

module "azure_resource_group" {
  source              = "./modules/azure_resource_group"
  resource_group_name = "prod-group"
  location            = "East US"
}
```

---

## Usage

1. ***Initialize Terraform***

From the project root:

```shell
terraform init
```
2. ***Plan the Infrastructure***

Preview the actions Terraform will perform:

```shell
terraform plan
```
3. ***Apply the Configuration***

Create the resources in AWS and Azure:

```shell
terraform apply
```
4. ***Outputs***

After applying, Terraform will display key resource attributes:
- EC2 instance ID.
- Public and private IP addresses.
- Azure resource group ID.

## Expanding the Project

***Adding a Staging Environment***

To create staging resources, add the following blocks to main.tf:

```
module "staging_aws_instance" {
  source         = "./modules/aws_instance"
  ami            = "ami-0c02fb55956c7d316"
  instance_type  = "t2.micro"
  instance_name  = "staging-instance"
}

module "staging_azure_group" {
  source              = "./modules/azure_resource_group"
  resource_group_name = "staging-group"
  location            = "West US"
}
```