# Creates the S3 bucket to store the Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "remote-state-edsoncarlos"  # Replace with a globally unique name

  tags = { # Adds tags for identification
    Name = "Terraform State Bucket"
  }
}

# Configures versioning for the S3 bucket
resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id # Refers to the bucket created above

  versioning_configuration {
    status = "Enabled" # Enables versioning to track changes in the state file
  }
}

# Creates a DynamoDB table to handle state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"        # Name of the DynamoDB table
  billing_mode = "PAY_PER_REQUEST"        # Pay only for operations performed
  hash_key     = "LockID"                 # Defines the primary key for state locking

  attribute {
    name = "LockID"                       # Configures the attribute 'LockID' as the primary key
    type = "S"                            # Specifies the type as a string
  }

  tags = { # Adds tags for identification
    Name = "Terraform Lock Table"
    Environment = "Dev"
  }
}