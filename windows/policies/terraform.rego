package terraform

# Deny security groups allowing unrestricted access (0.0.0.0/0)
deny[msg] {
  resource := input.resource.aws_security_group[_]
  ingress := resource.config.ingress[_]
  ingress.cidr_blocks[_] == "0.0.0.0/0"
  msg := sprintf("Security group %v allows unrestricted access (0.0.0.0/0)", [resource.name])
}

# Require S3 bucket encryption
deny[msg] {
  resource := input.resource.aws_s3_bucket[_]
  not input.resource.aws_s3_bucket_server_side_encryption_configuration[_]
  msg := sprintf("Bucket %v does not have encryption enabled", [resource.name])
}

