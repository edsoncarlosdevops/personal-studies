# Configures the remote backend for Terraform
terraform {
  backend "s3" {
    bucket         = "remote-state-edsoncarlos"          # Name of the S3 bucket
    key            = "ec2-instance/terraform.tfstate"           # Path to store the Terraform state file
    region         = "us-east-1"                         # AWS region
    dynamodb_table = "terraform-locks"                   # Name of the DynamoDB table for state locking
    encrypt        = true                                # Enables encryption for the state file
  }
}

resource "aws_instance" "remote-state-terraform" {
  ami           = "ami-0c02fb55956c7d316" 
  instance_type = "t2.micro"

  tags = {
    Name = "Example Instance-Edson-Carlos"
  }
}