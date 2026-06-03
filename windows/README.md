# 🪟 Windows Lab Modernization

## 📋 Sobre

Este diretório contém a automação completa para provisionamento e configuração de um laboratório Windows Domain Controller + Workstations na AWS, utilizando **Terraform**, **Ansible** e **GitHub Actions**.

## 🚀 Tecnologias e Ferramentas

| Categoria | Tecnologia |
|---|---|
| **Infra as Code** | Terraform (VPC, EC2, S3, Security Groups) |
| **Config Management** | Ansible (WinRM) |
| **CI/CD** | GitHub Actions (Validate, Apply, Destroy) |
| **Security** | Checkov, OPA, LAPS, Defender, CIS Benchmark |
| **Monitoring** | Prometheus, Grafana, Windows Exporter |
| **Cloud Hybrid** | Azure Arc, Defender for Cloud |
| **Active Directory** | AD DS, GPO, OUs, RunOnce automation |

## 🏗️ Estrutura

```
windows/
├── README.md                    # Este arquivo
├── ansible/
│   ├── ansible.cfg              # Configuração do Ansible
│   ├── requirements.yml         # Collections necessárias
│   ├── inventory/
│   │   └── dev.yml             # Inventário das VMs
│   ├── group_vars/
│   │   └── windows_workstations.yml  # Variáveis comuns
│   └── playbooks/
│       ├── 01-baseline.yml           # Updates, Firewall, WinRM
│       ├── 02-security-hardening.yml # Defender, LAPS, CIS
│       ├── 03-monitoring.yml         # Prometheus + Grafana
│       └── 04-azure-arc.yml          # Azure Arc hybrid mgmt
├── environments/
│   └── dev/
│       ├── main.tf              # Recursos principais
│       ├── variables.tf         # Variáveis
│       ├── outputs.tf           # Outputs + relatórios
│       ├── provider.tf          # AWS Provider + Backend
│       └── templates/
│           └── inventory.tpl    # Template inventário Ansible
├── modules/
│   ├── vpc/                     # VPC module
│   ├── s3/                      # S3 module
│   ├── security-group/          # Security Group module
│   └── windows-server/          # EC2 Windows module
├── scripts/
│   ├── configure-ad.ps1         # AD DS automation
│   └── setup.sh                 # Bootstrap helper
└── policies/
    └── terraform.rego           # OPA policies
```

## 🎯 Funcionalidades

- ✅ Domain Controller Windows Server 2022 automatizado
- ✅ Múltiplas workstations parametrizadas (count-based)
- ✅ Auto-generate de senhas (admin, DSRM)
- ✅ Segurança: Defender ASR, LAPS, CIS Level 1, NTLMv2
- ✅ Monitoramento: Prometheus + Grafana + Dashboard
- ✅ Azure Arc: Hybrid management, Defender for Cloud
- ✅ CI/CD: Validação, Security Scan, OPA, Apply, Destroy
- ✅ Relatório HTML de usuários gerado no GitHub Actions
- ✅ Inventário Ansible gerado automaticamente pelo Terraform

## 🔧 Como usar

```bash
# 1. Provisionar infraestrutura
cd environments/dev
terraform init
terraform apply -auto-approve

# 2. Gerar inventário Ansible
terraform output -raw ansible_inventory > ../../ansible/inventory/dev.yml

# 3. Configurar VMs com Ansible
cd ../../ansible
ansible-playbook playbooks/01-baseline.yml
ansible-playbook playbooks/02-security-hardening.yml
ansible-playbook playbooks/03-monitoring.yml
```

## 📊 Outputs Úteis

```bash
terraform output admin_password        # Senha do Administrator
terraform output safe_mode_password    # Senha DSRM do AD
terraform output lab_users             # Lista de usuários do AD
terraform output workstation_ips       # IPs das workstations
terraform output ansible_inventory     # Inventário para Ansible
```
