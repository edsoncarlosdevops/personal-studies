terraform {
  backend "s3" {
    bucket         = "remote-state-edsoncarlos"
    key            = "s3-bucket/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

resource "aws_s3_bucket" "example" {
  bucket = "example-bucket-edson-${random_pet.name}"

  tags = {
    Name = "Example S3 Bucket"
  }
}

resource "random_pet" "name" {}