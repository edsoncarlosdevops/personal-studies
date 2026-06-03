# Ansible Windows Automation

This directory contains Ansible playbooks for configuring Windows workstations after Terraform provisioning.

## Prerequisites

```bash
# Install Ansible (macOS)
brew install ansible

# Install required collections
ansible-galaxy collection install -r requirements.yml
```

## How to use

### 1. Update inventory with actual VM IPs

After `terraform apply`, get the IPs:

```bash
terraform output -json > ../ansible/inventory/vars.json
```

Then update `inventory/dev.yml` with the actual IPs and admin password.

### 2. Run playbooks

```bash
# Run baseline configuration (updates, firewall, security)
ansible-playbook playbooks/01-baseline.yml

# Run only specific tags
ansible-playbook playbooks/01-baseline.yml --tags firewall,security
```

## Playbooks

| Playbook | Description | Tags |
|---|---|---|
| `01-baseline.yml` | Windows Updates, Firewall, WinRM, Security logging | `updates`, `firewall`, `security`, `winrm`, `verify` |
| `02-security-hardening.yml` | Defender, LAPS, CIS Benchmark, Audit, Hardening | `defender`, `laps`, `cis`, `audit`, `hardening`, `verify` |
| `03-monitoring.yml` | Prometheus Exporter, Prometheus Server, Grafana, Dashboard | `prometheus`, `grafana`, `dashboard`, `verify` |
| `04-azure-arc.yml` | Azure Arc Hybrid Management, Defender for Cloud, Update Management | `install`, `connect`, `defender_ext`, `verify`, `disconnect` |

## How to use

### 1. Update inventory with actual VM IPs

After `terraform apply`, generate the inventory automatically:

```bash
cd environments/dev
terraform output -raw ansible_inventory > ../../ansible/inventory/dev.yml
```

### 2. Run playbooks (in order)

```bash
# Step 1: Baseline configuration
ansible-playbook playbooks/01-baseline.yml

# Step 2: Security hardening
ansible-playbook playbooks/02-security-hardening.yml

# Step 3: Monitoring setup
ansible-playbook playbooks/03-monitoring.yml

# Step 4: Azure Arc (requires Azure credentials)
ansible-playbook playbooks/04-azure-arc.yml \
  --extra-vars "vault_azure_tenant_id=xxx vault_azure_sp_id=xxx vault_azure_sp_secret=xxx vault_azure_subscription_id=xxx"

# Or run specific tags only
ansible-playbook playbooks/04-azure-arc.yml --tags install,connect
```

### 3. Access Monitoring

After running the monitoring playbook:

| Service | URL | Credentials |
|---|---|---|
| Prometheus | `http://<VM_IP>:9090` | - |
| Grafana | `http://<VM_IP>:3000` | `admin:admin` |
| Windows Exporter | `http://<VM_IP>:9182/metrics` | - |

### 4. Azure Arc Cleanup

To disconnect a machine from Azure Arc:

```bash
ansible-playbook playbooks/04-azure-arc.yml --tags disconnect --extra-vars "..." 
```

## Structure

```
ansible/
├── ansible.cfg              # Ansible configuration
├── requirements.yml         # Required collections
├── README.md               # Usage instructions
├── inventory/
│   └── dev.yml             # Dev environment inventory
├── group_vars/
│   └── windows_workstations.yml  # Common connection vars
└── playbooks/
    ├── 01-baseline.yml           # First-run configuration
    ├── 02-security-hardening.yml # Security hardening
    ├── 03-monitoring.yml         # Prometheus + Grafana setup
    └── 04-azure-arc.yml          # Azure Arc hybrid management
```
