provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

resource "aws_s3_bucket" "this" {
  bucket = "${var.environment}-bucket-${var.sufixo}"

  force_destroy = true
}

