resource "aws_security_group" "windows_rdp" {
  name        = "${var.environment}-windows-rdp-sg"
  description = "Allows RDP (3389) and WinRM (5985-5986) access"
  vpc_id      = var.vpc_id

  # In production, restrict to your office/VPN CIDR instead of 0.0.0.0/0
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.allowed_rdp_cidr]
    description = "Allow RDP access from trusted IPs"
  }

  ingress {
    from_port   = 5985
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = [var.allowed_rdp_cidr]
    description = "Allow WinRM access from trusted IPs"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  lifecycle {
    # NOTE: prevent_destroy is disabled for this test environment.
    # In production, set prevent_destroy = true to avoid accidental deletion
    # of the security group which could disrupt running instances.
    prevent_destroy = false
  }

  tags = {
    Name        = "${var.environment}-windows-rdp-sg"
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = "windows-ad-terraform"
  }
}

