# Terraform Project for Remote State Management and AWS Resource Provisioning

This project demonstrates how to manage Terraform remote states with S3 and DynamoDB, as well as provision AWS resources (e.g., EC2 instances, S3 buckets, and security groups) using modular configurations.

---

## Project Structure

The project is organized into separate directories for each AWS resource, with each directory managing its own Terraform state.

```
terraform-project/
├── ec2-instance/       # Manages EC2 instance provisioning
│   ├── backend.tf      # Backend configuration for remote state
│   ├── main.tf         # EC2 instance configuration
│   ├── provider.tf     # AWS provider configuration
├── s3-bucket/          # Manages S3 bucket creation
│   ├── backend.tf      # Backend configuration for remote state
│   ├── main.tf         # S3 bucket configuration
│   ├── provider.tf     # AWS provider configuration
├── security-group/     # Manages Security Group setup
│   ├── backend.tf      # Backend configuration for remote state
│   ├── main.tf         # Security Group configuration
│   ├── provider.tf     # AWS provider configuration
└── provider.tf         # Centralized provider configuration for the project
```


# Key Features

1. **Remote State Management:**
   - Uses an S3 bucket (`remote-state-edsoncarlos`) to store Terraform states for each directory.
   - Implements DynamoDB for state locking to avoid simultaneous changes.
   - Versioning enabled on the S3 bucket to track state file changes.

2. **AWS Resource Provisioning:**
   - EC2 instance (`ec2-instance` directory).
   - S3 bucket (`s3-bucket` directory).
   - Security group (`security-group` directory).

3. **Modular Approach:**
   - Each directory operates independently with its own Terraform state.

---

# Setup Instructions

## 1. Prerequisites
- Install **Terraform** (version 1.0 or higher).
- AWS credentials configured locally (e.g., via `~/.aws/credentials`).

## 2. Initialize the Project
1. Navigate to the directory you want to work on (e.g., `ec2-instance`):
   ```bash
   cd ec2-instance


## 3. Apply Changes

1. Apply the Terraform configuration in the directory:
   ```shel
   terraform apply
    ```

2.	Repeat for other directories (s3-bucket and security-group) as needed.

## 4. Verify Remote State

1. Open the AWS S3 console.
2. Check the `remote-state-edsoncarlos` bucket for state files:
   - `ec2-instance/terraform.tfstate`
   - `s3-bucket/terraform.tfstate`
   - `security-group/terraform.tfstate`
3. Verify version history for each state file.

---

## Customizing the Configuration

### 1. AWS Region

Update the AWS region in `provider.tf`:

```
provider "aws" {
  region = "us-east-1"  # Change to your desired region
}
```

### 2. State File Keys

Modify the `key` in `backend.tf` to adjust the location of the state file:
```
key = "ec2-instance/terraform.tfstate"
```


## 3. Tags

Ensure all resources include appropriate tags for identification:

```
tags = {
  Name = "Example Resource"
}
```


## Troubleshooting

### 1. State Locking Errors

If a state locking error occurs:
1. Check the DynamoDB table (`terraform-locks`) for active locks.
2. Manually release the lock if needed via the AWS console.

### 2. Missing State Files

Ensure the S3 bucket (`remote-state-edsoncarlos`) exists and is properly configured with versioning enabled.