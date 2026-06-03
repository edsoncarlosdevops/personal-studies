data "aws_ami" "windows" {
  most_recent = true
  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }
  owners = ["amazon"]
}

resource "aws_instance" "windows" {
  ami                    = data.aws_ami.windows.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [var.security_group_id]

  get_password_data = false

  # EBS optimization for better performance
  ebs_optimized = true

  # Enable detailed monitoring
  monitoring = true

  # Metadata service - enforce IMDSv2 only
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Root volume encryption
  root_block_device {
    encrypted = true
  }

  # Longer timeout for Windows boot and AD configuration
  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }

  user_data = <<-EOF
    <powershell>
    $ErrorActionPreference = 'Stop'
    $logFile = 'C:\Logs\userdata.log'

    Start-Transcript -Path $logFile -Append

    try {
        Write-Host "=== Setting hostname ==="
        if ("${var.hostname}") {
            Rename-Computer -NewName "${var.hostname}" -Force
        }

        Write-Host "=== Creating directories ==="
        New-Item -ItemType Directory -Force -Path 'C:\Scripts' | Out-Null
        New-Item -ItemType Directory -Force -Path 'C:\Logs' | Out-Null

        Write-Host "=== Setting Administrator password ==="
        $password = ConvertTo-SecureString "${var.admin_password}" -AsPlainText -Force
        Set-LocalUser -Name Administrator -Password $password

        Write-Host "=== Configuring Firewall rules (specific ports only) ==="
        # Allow RDP (3389)
        netsh advfirewall firewall add rule name="RDP (3389)" dir=in action=allow protocol=tcp localport=3389
        # Allow WinRM HTTP (5985)
        netsh advfirewall firewall add rule name="WinRM HTTP (5985)" dir=in action=allow protocol=tcp localport=5985
        # Allow WinRM HTTPS (5986)
        netsh advfirewall firewall add rule name="WinRM HTTPS (5986)" dir=in action=allow protocol=tcp localport=5986
        # Allow DNS (53) - required for AD
        netsh advfirewall firewall add rule name="DNS (53)" dir=in action=allow protocol=udp localport=53
        # Allow Kerberos (88) - required for AD
        netsh advfirewall firewall add rule name="Kerberos (88)" dir=in action=allow protocol=tcp localport=88
        netsh advfirewall firewall add rule name="Kerberos (88) UDP" dir=in action=allow protocol=udp localport=88
        # Allow LDAP (389) - required for AD
        netsh advfirewall firewall add rule name="LDAP (389)" dir=in action=allow protocol=tcp localport=389
        # Allow LDAP SSL (636)
        netsh advfirewall firewall add rule name="LDAP SSL (636)" dir=in action=allow protocol=tcp localport=636
        # Allow SMB (445) - required for AD replication
        netsh advfirewall firewall add rule name="SMB (445)" dir=in action=allow protocol=tcp localport=445
        # Allow ICMPv4 (ping) for testing
        netsh advfirewall firewall add rule name="ICMPv4 (ping)" dir=in action=allow protocol=icmpv4

        Write-Host "=== Configuring WinRM ==="
        winrm set winrm/config/service/auth '@{Basic="true"}'
        winrm set winrm/config/service '@{AllowUnencrypted="true"}'
        winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="2048"}'

        Write-Host "=== Copying configure-ad.ps1 script ==="
        @'
${file("${path.module}/../../scripts/configure-ad.ps1")}
'@ | Set-Content -Path 'C:\Scripts\configure-ad.ps1' -Encoding UTF8

        Write-Host "=== Setting Safe Mode password for AD ==="
        $env:SAFE_MODE_PASS = "${var.safe_mode_password}"

        Write-Host "=== Registering RunOnce to execute script after every boot ==="
        $runOncePath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce'
        Set-ItemProperty -Path $runOncePath -Name 'ConfigureAD' -Value "powershell.exe -ExecutionPolicy Bypass -File C:\Scripts\configure-ad.ps1"

        Write-Host "=== Executing configure-ad.ps1 ==="
        & C:\Scripts\configure-ad.ps1
    }
    catch {
        Write-Host "=== ERROR: $_ ===" -ForegroundColor Red
        $_ | Out-File -FilePath 'C:\Logs\userdata-error.log' -Append
    }
    finally {
        Write-Host "=== Userdata completed ==="
        Stop-Transcript
    }
    </powershell>
  EOF

  tags = {
    Name        = var.hostname != null ? var.hostname : "${var.environment}-windows-server"
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = "windows-ad-terraform"
  }
}

