#!/bin/bash
# Script to prepare the environment before terraform init
# Creates the state bucket with a unique name

RANDOM_SUFFIX=$(date +%s | md5 | head -c 8)
BUCKET="terraform-state-windows-ad-${RANDOM_SUFFIX}"
REGION="us-east-1"

echo "=== Environment Setup ==="
echo "Bucket: $BUCKET"

# Create the bucket
aws s3 mb "s3://$BUCKET" --region $REGION
aws s3api put-bucket-versioning \
    --bucket $BUCKET \
    --versioning-configuration Status=Enabled

echo "Bucket created with versioning enabled"

# Update provider.tf with the bucket name
cd environments/dev
sed -i '' "s/bucket         = \"terraform-state-windows-ad.*\"/bucket         = \"$BUCKET\"/" provider.tf

echo ""
echo "Setup complete! Now run:"
echo "  cd environments/dev"
echo "  terraform init"
echo "  terraform apply"
