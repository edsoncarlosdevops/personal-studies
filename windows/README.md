# AWS Windows Domain Controller & Workstations Provisioning

This project automates the provisioning and configuration of a Windows Server 2022 Active Directory Domain Controller (DC) with multiple parametrized workstations on AWS using **Terraform**, **Ansible**, and **PowerShell**. It includes a fully automated post-installation configuration cycle, security hardening, monitoring, cloud hybrid management, and continuous integration/continuous deployment (CI/CD) workflows.

---

## Architecture

- **AWS Infrastructure (Terraform)**:
  - **VPC**: Dedicated Virtual Private Cloud with a public subnet, internet gateway, and route tables for ingress/egress routing.
  - **Domain Controller**: Windows Server 2022 (`t3.large`) provisioned with Active Directory Domain Services.
  - **Workstations**: Windows Server 2022 (`t3.medium`) provisioned via `count` — fully parametrized for scalability (configurable from 1 to N).
  - **S3 Bucket**: Secure storage resource provisioned with versioning, bucket lifecycle policies, and server-side encryption (SSE-KMS) with customer managed keys.
  - **Security Group**: Restricts RDP (port 3389) and WinRM (port 5985) dynamically to the deployment host's public IP address (retrieved in real-time via `api.ipify.org`).

- **OS Configuration (PowerShell + Ansible)**:
  - **Active Directory (PowerShell)**: Automated AD DS installation and forest promotion using a two-phase `RunOnce` cycle.
  - **Workstations Configuration (Ansible)**: 4 playbooks for baseline, security hardening, monitoring, and Azure Arc hybrid management.
  - **Organization Unit (OU) and batch user provisioning**.
  - **Group Policy Objects (GPOs) enforcement**.
  - **Scheduled task implementation**.

---

## Key Design Decisions

- **Two-Phase Agentless Provisioning**: Used native PowerShell combined with the Windows `RunOnce` registry key. This eliminates the need for external configuration management tooling (e.g., Ansible, Chef) while successfully navigating the mandatory system reboot required during Active Directory promotion.
- **Ansible for Post-Deploy Configuration**: After the DC is ready, Ansible (via WinRM) configures workstations with updates, security policies (Defender, LAPS, CIS), monitoring agents (Prometheus + Grafana), and cloud extensions (Azure Arc) — enabling a clear separation of concerns (Terraform = infra, Ansible = config).
- **Dynamic IP Restriction**: Rather than exposing RDP (port 3389) to `0.0.0.0/0`, the configuration dynamically fetches the deployment operator's public IP via `api.ipify.org` during execution, restricting ingress traffic specifically to the authorized administrator.
- **Automated Policy and Security Scanning**: Included Checkov (SAST) and Open Policy Agent (OPA) directly in the CI/CD pull request lifecycle. This ensures compliance checks and security scans are executed prior to resource modification.
- **Secure Password Lifecycle**: Used Terraform's `random_password` provider to generate the Administrator and DSRM (Safe Mode) passwords programmatically, outputting them securely via outputs rather than hardcoding credentials in configuration scripts.
- **Count-Based Workstation Scaling**: Workstations are created using Terraform's `count` metaparameter, controlled by a single variable (`workstation_count`). No code duplication — add 3 or 30 workstations by changing one number.

---

## CI/CD Workflows (GitHub Actions)

The repository provides automated pipelines under `.github/workflows/` to manage code quality, security, and deployment:

### 1. Terraform Validate (`terraform-validate.yaml`)
- **Trigger**: Automatic on `push` and `pull_request` to the `main` branch.
- **Jobs**:
  - **Validate**: Formats (`terraform fmt -check`), initializes without backend (`terraform init -backend=false`), and runs static validation (`terraform validate`).
  - **Security Scan**: Utilizes **Checkov** to run static application security testing (SAST) on Terraform configurations.
  - **OPA Policy Check**: Executes Open Policy Agent (OPA) checks to ensure compliance with organization infrastructure policies.

### 2. Terraform Apply (`terraform-apply.yaml`)
- **Trigger**: Manual (`workflow_dispatch`).
- **Jobs**:
  - **Plan**: Generates and uploads the execution plan (`tfplan`) as an artifact.
  - **Apply**: Downloads the artifact and applies changes. Employs GitHub Secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`) for AWS authentication.
  - **Lab Report**: Generates an HTML artifact (`lab-users-report`) with the complete list of provisioned users and workstations.
  - **Summary**: Writes the deployment output parameters directly to the GitHub Action workflow summary.

### 3. Terraform Destroy (`terraform-destroy.yaml`)
- **Trigger**: Manual (`workflow_dispatch`).
- **Jobs**:
  - **Destroy**: Tear down all resources provisioned by the workspace to prevent active charges.

---

## How the Automation Cycle Works

The OS configuration runs completely unattended by leveraging EC2 UserData and Windows `RunOnce` registry settings:

### Phase 1: Boot & AD DS Installation
- The instance boots and retrieves the `configure-ad.ps1` script.
- UserData triggers the initial run of the script.
- The script installs the AD DS role and promotes the server to a Domain Controller for the `lab.local` domain.
- The promotion process triggers a mandatory system reboot.
- Before rebooting, a registry key is added to `HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce` to resume script execution.

### Phase 2: Post-Reboot Configuration
- Upon reboot, the system automatically logs in as Administrator and resumes execution via `RunOnce`.
- The script detects that the AD DS role is active and proceeds with:
  - Creating the target OU (`OU=LabUsers,DC=lab,DC=local`).
  - Provisioning batch users (`user1@lab.local` through `userN@lab.local`) with standard user and remote access privileges.
  - Creating and linking GPOs (Notepad auto-launch and C:\ drive restriction).
  - Scheduling a daily reboot task at 03:00 AM.
  - Finalizing system security and removing the `RunOnce` registry key.

### Phase 3: Post-Provision Configuration (Ansible)
After the DC and workstations are provisioned by Terraform, Ansible configures the workstations:
- **Baseline**: Windows Updates, Firewall rules, WinRM tuning, timezone.
- **Security Hardening**: Windows Defender (ASR rules), LAPS installation, CIS Benchmark Level 1, advanced audit policies.
- **Monitoring**: Prometheus Windows Exporter, Prometheus Server, Grafana dashboard.
- **Azure Arc**: Connected Machine Agent, Defender for Cloud, Update Management, Azure Policy.

---

## Deployment Instructions

### Option A: Local Deployment

1. **Initialize Backend and Providers**:
   ```bash
   cd environments/dev
   terraform init
   ```

2. **(Optional) Customize workstation count**:
   ```bash
   # Edit terraform.tfvars or use -var:
   # workstation_count = 5
   # users_count = 15
   ```

3. **Apply Configurations**:
   ```bash
   terraform apply -auto-approve
   ```

4. **Generate Ansible inventory**:
   ```bash
   terraform output -raw ansible_inventory > ../../ansible/inventory/dev.yml
   ```

5. **Configure workstations with Ansible**:
   ```bash
   cd ../../ansible
   ansible-playbook playbooks/01-baseline.yml
   ansible-playbook playbooks/02-security-hardening.yml
   ansible-playbook playbooks/03-monitoring.yml
   ```

### Option B: CI/CD Deployment

1. Configure AWS credentials as GitHub Secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`).
2. Run the **Terraform Apply** workflow manually in the GitHub Actions tab.
3. After apply completes, download the `lab-users-report` artifact for the user list.
4. Access the output details in the GitHub Run Summary.

---

## Credentials & RDP Access

After running `terraform apply`, retrieve the deployment credentials and connection parameters directly from the Terraform outputs:

### 1. Host IP & Connection Command
- **DC Public IP**: Retrieve via `terraform output -raw dc_public_ip`
- **Workstation IPs**: Retrieve via `terraform output workstation_ips`
- **RDP Direct Command**: `mstsc /v:<ip>`

### 2. Administrator Account (Local Admin)
- **Username**: `.\Administrator`
- **Password**: Retrieve via `terraform output -raw admin_password`
- **DSRM Password**: Retrieve via `terraform output -raw safe_mode_password`

### 3. Lab Domain Accounts (Standard Domain Users)
- **Usernames**: `user1@lab.local` through `userN@lab.local` (or `LAB\userN`)
- **Password**: `P@ssw0rd123!`
- **Access Privilege**: Standard domain users, members of `Domain Users` and `Remote Desktop Users` (use these accounts to test GPO limitations).

### 4. Monitoring Access
- **Prometheus**: `http://<WORKSTATION_IP>:9090`
- **Grafana**: `http://<WORKSTATION_IP>:3000` (credentials: `admin:admin`)
- **Windows Exporter**: `http://<WORKSTATION_IP>:9182/metrics`

---

## Project Structure

```
├── ansible/                              # Ansible playbooks (WinRM)
│   ├── ansible.cfg                       # Ansible configuration
│   ├── requirements.yml                  # Required collections
│   ├── inventory/
│   │   └── dev.yml                       # Auto-generated inventory
│   ├── group_vars/
│   │   └── windows_workstations.yml      # Common connection variables
│   └── playbooks/
│       ├── 01-baseline.yml               # Updates, Firewall, WinRM
│       ├── 02-security-hardening.yml     # Defender, LAPS, CIS
│       ├── 03-monitoring.yml            # Prometheus + Grafana
│       └── 04-azure-arc.yml              # Azure Arc hybrid mgmt
│
├── environments/
│   ├── bootstrap/          # Terraform state backend infrastructure
│   └── dev/                # Development environment workspace
│       ├── main.tf         # Main declaration of modules and variables
│       ├── variables.tf    # Parametrized variables (workstation_count, users_count)
│       ├── outputs.tf      # Standard outputs (IP, credentials, inventory)
│       ├── provider.tf     # AWS Provider and S3 Backend configuration
│       ├── terraform.tfvars # Dev environment values
│       └── templates/
│           └── inventory.tpl # Ansible inventory template
│
├── modules/
│   ├── vpc/                # Virtual Private Cloud networking module
│   ├── s3/                 # Provisioning of the setup script storage bucket
│   ├── security-group/     # Ingress rules with dynamic IP fetching
│   └── windows-server/     # Windows EC2 instance and UserData boot cycle
│
├── policies/
│   └── terraform.rego      # Rego files for Open Policy Agent (OPA) validation
│
├── scripts/
│   ├── configure-ad.ps1    # Automated AD DS promotion & post-reboot configuration
│   └── setup.sh            # Local helper bootstrap script
│
└── .github/workflows/
    ├── terraform-validate.yaml           # Format + Checkov + OPA
    ├── terraform-apply.yaml              # Plan + Apply + HTML Report
    └── terraform-destroy.yaml            # Destroy all resources
```

---

## Deliverables & Configurations

### Domain Settings
- **Forest Domain**: `lab.local`
- **Functional Level**: Windows Server 2016

### Group Policy Objects (GPOs)
- **Launch Notepad on Logon**: Automatically runs `notepad.exe` for all users on login.
- **Restrict C Drive Access**: Restricts standard domain users (non-admins) from accessing `C:\` via Explorer.

### Task Scheduler
- **Name**: `DailyReboot`
- **Schedule**: Every day at 03:00 AM.
- **Action**: `shutdown.exe /r /t 0 /f`

### Active Directory Assets
- **OU**: `OU=LabUsers,DC=lab,DC=local`
- **Lab Users**: `user1@lab.local` through `userN@lab.local` (configurable count via `users_count` variable).
- **Password**: `P@ssw0rd123!` (standardized for lab purposes).
- **Groups**: `Domain Users` and `Remote Desktop Users`.

### Ansible Playbooks Summary

| Playbook | Description | Key Features |
|---|---|---|
| `01-baseline.yml` | First-run configuration | Updates, Firewall, WinRM, Timezone, Logging |
| `02-security-hardening.yml` | Security hardening | Defender ASR, LAPS, CIS Level 1, Audit Policies |
| `03-monitoring.yml` | Monitoring setup | Prometheus Exporter, Prometheus Server, Grafana Dashboard |
| `04-azure-arc.yml` | Cloud hybrid management | Arc Agent, Defender for Cloud, Update Management, Policy |

---

## Post-Deployment Verification

Log into the Domain Controller using RDP (using the parameters retrieved in the **Credentials & RDP Access** section) and execute the following PowerShell commands to verify the setup:

```powershell
# Verify Domain status
Get-ADDomain | Select-Object DNSRoot, NetBIOSName, DomainMode

# Verify Active GPOs
gpresult /r

# Verify Scheduled Task
Get-ScheduledTask -TaskName DailyReboot | Select-Object TaskName, State, Actions

# Verify Lab Users
Get-ADUser -Filter * -SearchBase "OU=LabUsers,DC=lab,DC=local" |
    Format-Table Name, SamAccountName, Enabled

# Verify Domain Computers
Get-ADComputer -Filter * | Format-Table Name, Enabled

# Verify Prometheus metrics (on any workstation)
Invoke-RestMethod -Uri "http://localhost:9182/metrics" | Select-Object -First 20

# Verify Azure Arc connection (if configured)
& "$env:ProgramFiles\AzureConnectedMachineAgent\azcmagent.exe" show
```

---

## Production Recommendations

For staging or production deployments, address the following security and architecture details:
- **Network Isolation**: Deploy the EC2 instance in a private subnet and configure AWS Systems Manager (SSM) for management instead of exposing RDP port 3389.
- **State Management**: Use remote state storage with state locking (e.g., S3 backend with DynamoDB locking) — already configured in `bootstrap/`.
- **Resource Lifecycle**: Implement `prevent_destroy = true` lifecycle blocks on critical assets.
- **Secrets Management**: Store sensitive passwords in AWS Secrets Manager instead of Terraform outputs.
- **Logging & Monitoring**: Enable AWS CloudTrail, VPC Flow Logs, and ship Windows Event logs to a centralized log management tool (e.g., Azure Log Analytics via Arc).
- **High Availability**: Deploy a second Domain Controller in a different Availability Zone.
- **Backup**: Configure regular AD DS backups using Windows Server Backup or AWS Backup.
- **Patch Management**: Use Azure Update Management (via Arc) or AWS Systems Manager Patch Manager for automated patching.
