# Provisionamento de Domain Controller Windows e Workstations na AWS

Este projeto automatiza o provisionamento e configuração de um **Domain Controller Windows Server 2022** com **múltiplas workstations parametrizadas** na AWS utilizando **Terraform**, **Ansible** e **PowerShell**. Inclui ciclo de configuração pós-instalação totalmente automatizado, hardening de segurança, monitoramento, gerenciamento de cloud híbrida e pipelines de integração/entrega contínua (CI/CD).

---

## Arquitetura

- **Infraestrutura AWS (Terraform)**:
  - **VPC**: Virtual Private Cloud dedicada com sub-rede pública, internet gateway e tabelas de roteamento.
  - **Domain Controller**: Windows Server 2022 (`t3.large`) provisionado com Active Directory Domain Services.
  - **Workstations**: Windows Server 2022 (`t3.medium`) provisionadas via `count` — totalmente parametrizado para escalabilidade (configurável de 1 a N).
  - **S3 Bucket**: Recurso de armazenamento seguro com versionamento, políticas de ciclo de vida e criptografia SSE-KMS.
  - **Security Group**: Restringe RDP (porta 3389) e WinRM (porta 5985) dinamicamente ao IP público do host de implantação (obtido em tempo real via `api.ipify.org`).

- **Configuração do SO (PowerShell + Ansible)**:
  - **Active Directory (PowerShell)**: Instalação automatizada do AD DS e promoção de floresta usando ciclo de duas fases com `RunOnce`.
  - **Configuração das Workstations (Ansible)**: 4 playbooks para baseline, hardening de segurança, monitoramento e Azure Arc.
  - **Criação de Unidade Organizacional (OU) e provisionamento de usuários em lote**.
  - **Aplicação de Objetos de Política de Grupo (GPOs)**.
  - **Implementação de tarefa agendada**.

---

## Decisões de Design

- **Provisionamento Agentless em Duas Fases**: PowerShell nativo combinado com a chave de registro `RunOnce` do Windows. Isso elimina a necessidade de ferramentas externas de gerenciamento de configuração, enquanto navega com sucesso pela reinicialização obrigatória do sistema durante a promoção do Active Directory.
- **Ansible para Configuração Pós-Deploy**: Após o DC estar pronto, o Ansible (via WinRM) configura as workstations com atualizações, políticas de segurança (Defender, LAPS, CIS), agentes de monitoramento (Prometheus + Grafana) e extensões de cloud (Azure Arc) — permitindo clara separação de responsabilidades (Terraform = infra, Ansible = config).
- **Restrição Dinâmica de IP**: Em vez de expor RDP (porta 3389) para `0.0.0.0/0`, a configuração obtém dinamicamente o IP público do operador via `api.ipify.org`, restringindo o tráfego de entrada especificamente ao administrador autorizado.
- **Varredura Automática de Políticas e Segurança**: Checkov (SAST) e Open Policy Agent (OPA) incluídos diretamente no ciclo de vida de pull requests do CI/CD. Isso garante que verificações de conformidade e varreduras de segurança sejam executadas antes da modificação dos recursos.
- **Ciclo de Vida Seguro de Senhas**: Uso do provider `random_password` do Terraform para gerar as senhas do Administrador e DSRM (Modo de Segurança) programaticamente, exibindo-as seguramente via outputs em vez de codificá-las nos scripts.
- **Escalonamento Baseado em Count**: Workstations são criadas usando o meta-parâmetro `count` do Terraform, controlado por uma única variável (`workstation_count`). Sem duplicação de código — adicione 3 ou 30 workstations alterando apenas um número.

---

## Workflows CI/CD (GitHub Actions)

O repositório fornece pipelines automatizados em `.github/workflows/` para gerenciar qualidade de código, segurança e implantação:

### 1. Terraform Validate (`terraform-validate.yaml`)
- **Gatilho**: Automático em `push` e `pull_request` para a branch `main`.
- **Jobs**:
  - **Validate**: Formata (`terraform fmt -check`), inicializa sem backend (`terraform init -backend=false`) e executa validação estática (`terraform validate`).
  - **Security Scan**: Utiliza **Checkov** para executar testes de segurança estáticos (SAST) nas configurações do Terraform.
  - **OPA Policy Check**: Executa verificações do Open Policy Agent (OPA) para garantir conformidade com as políticas de infraestrutura.

### 2. Terraform Apply (`terraform-apply.yaml`)
- **Gatilho**: Manual (`workflow_dispatch`).
- **Jobs**:
  - **Plan**: Gera e envia o plano de execução (`tfplan`) como artefato.
  - **Apply**: Baixa o artefato e aplica as alterações. Utiliza GitHub Secrets para autenticação AWS.
  - **Relatório do Lab**: Gera um artefato HTML (`lab-users-report`) com a lista completa de usuários e workstations provisionados.
  - **Sumário**: Escreve os parâmetros de saída diretamente no sumário da execução do GitHub Actions.

### 3. Terraform Destroy (`terraform-destroy.yaml`)
- **Gatilho**: Manual (`workflow_dispatch`).
- **Jobs**:
  - **Destroy**: Remove todos os recursos provisionados para evitar custos ativos.

---

## Como Funciona o Ciclo de Automação

A configuração do SO é executada de forma completamente autônoma, utilizando o UserData da EC2 e as configurações de registro `RunOnce` do Windows:

### Fase 1: Boot e Instalação do AD DS
- A instância inicializa e executa o script `configure-ad.ps1` via UserData.
- O script instala o papel AD DS e promove o servidor a Domain Controller para o domínio `lab.local`.
- O processo de promoção aciona uma reinicialização obrigatória do sistema.
- Antes de reiniciar, uma chave de registro é adicionada em `HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce` para retomar a execução.

### Fase 2: Configuração Pós-Reinicialização
- Após a reinicialização, o sistema faz login automaticamente como Administrador e retoma a execução via `RunOnce`.
- O script detecta que o papel AD DS está ativo e prossegue com:
  - Criação da OU alvo (`OU=LabUsers,DC=lab,DC=local`).
  - Provisionamento de usuários em lote (`user1@lab.local` até `userN@lab.local`).
  - Criação e vinculação de GPOs (Notepad na inicialização e restrição da unidade C:\ ).
  - Agendamento de tarefa de reinicialização diária às 03:00.
  - Finalização da segurança do sistema e remoção da chave `RunOnce`.

### Fase 3: Configuração Pós-Provisionamento (Ansible)
Após o DC e as workstations serem provisionados pelo Terraform, o Ansible configura as workstations:
- **Baseline**: Windows Updates, regras de Firewall, ajuste WinRM, fuso horário.
- **Hardening de Segurança**: Windows Defender (regras ASR), instalação do LAPS, CIS Benchmark Level 1, auditoria avançada.
- **Monitoramento**: Prometheus Windows Exporter, Prometheus Server, dashboard Grafana.
- **Azure Arc**: Connected Machine Agent, Defender for Cloud, Update Management, Azure Policy.

---

## Instruções de Implantação

### Opção A: Implantação Local

1. **Inicializar Backend e Providers**:
   ```bash
   cd environments/dev
   terraform init
   ```

2. **(Opcional) Personalizar quantidade de workstations**:
   ```bash
   # Edite terraform.tfvars ou use -var:
   # workstation_count = 5
   # users_count = 15
   ```

3. **Aplicar Configurações**:
   ```bash
   terraform apply -auto-approve
   ```

4. **Gerar inventário do Ansible**:
   ```bash
   terraform output -raw ansible_inventory > ../../ansible/inventory/dev.yml
   ```

5. **Configurar workstations com Ansible**:
   ```bash
   cd ../../ansible
   ansible-playbook playbooks/01-baseline.yml
   ansible-playbook playbooks/02-security-hardening.yml
   ansible-playbook playbooks/03-monitoring.yml
   ```

### Opção B: Implantação via CI/CD

1. Configure as credenciais AWS como GitHub Secrets.
2. Execute o workflow **Terraform Apply** manualmente na aba GitHub Actions.
3. Após a conclusão, baixe o artefato `lab-users-report` para a lista de usuários.
4. Acesse os detalhes dos outputs no sumário da execução.

---

## Credenciais e Acesso RDP

Após executar `terraform apply`, recupere as credenciais e parâmetros de conexão diretamente dos outputs do Terraform:

### 1. IP do Host e Comando de Conexão
- **IP do DC**: `terraform output -raw dc_public_ip`
- **IPs das Workstations**: `terraform output workstation_ips`
- **Comando RDP**: `mstsc /v:<ip>`

### 2. Conta de Administrador (Admin Local)
- **Usuário**: `.\Administrator`
- **Senha**: `terraform output -raw admin_password`
- **Senha DSRM**: `terraform output -raw safe_mode_password`

### 3. Contas de Domínio do Lab (Usuários Padrão)
- **Usuários**: `user1@lab.local` até `userN@lab.local` (ou `LAB\userN`)
- **Senha Temporária**: `P@ssw0rd123!` (usuários **DEVEM redefinir a senha no primeiro login** — configurado via `-ChangePasswordAtLogon $true`)
- **Privilégio**: Usuários padrão do domínio, membros de `Domain Users` e `Remote Desktop Users`.

### 4. Acesso ao Monitoramento
- **Prometheus**: `http://<IP_WORKSTATION>:9090`
- **Grafana**: `http://<IP_WORKSTATION>:3000` (credenciais: `admin:admin`)
- **Windows Exporter**: `http://<IP_WORKSTATION>:9182/metrics`

---

## Estrutura do Projeto

```
├── ansible/                              # Playbooks Ansible (WinRM)
│   ├── ansible.cfg                       # Configuração do Ansible
│   ├── requirements.yml                  # Collections necessárias
│   ├── inventory/
│   │   └── dev.yml                       # Inventário gerado automaticamente
│   ├── group_vars/
│   │   └── windows_workstations.yml      # Variáveis de conexão comuns
│   └── playbooks/
│       ├── 01-baseline.yml               # Updates, Firewall, WinRM
│       ├── 02-security-hardening.yml     # Defender, LAPS, CIS
│       ├── 03-monitoring.yml            # Prometheus + Grafana
│       └── 04-azure-arc.yml              # Azure Arc
│
├── environments/
│   ├── bootstrap/          # Infraestrutura do backend Terraform
│   └── dev/                # Ambiente de desenvolvimento
│       ├── main.tf         # Declaração principal de módulos e variáveis
│       ├── variables.tf    # Variáveis parametrizadas
│       ├── outputs.tf      # Outputs (IP, credenciais, inventário)
│       ├── provider.tf     # Provider AWS e Backend S3
│       ├── terraform.tfvars # Valores do ambiente dev
│       └── templates/
│           └── inventory.tpl # Template do inventário Ansible
│
├── modules/
│   ├── vpc/                # Módulo de rede VPC
│   ├── s3/                 # Módulo de bucket S3
│   ├── security-group/     # SG com IP dinâmico
│   └── windows-server/     # EC2 Windows + UserData
│
├── policies/
│   └── terraform.rego      # Políticas OPA para compliance
│
├── scripts/
│   ├── configure-ad.ps1    # Automação AD DS (2 fases)
│   └── setup.sh            # Script de bootstrap local
│
└── .github/workflows/
    ├── terraform-validate.yaml           # Format + Checkov + OPA
    ├── terraform-apply.yaml              # Plan + Apply + Relatório HTML
    └── terraform-destroy.yaml            # Destruir todos os recursos
```

---

## Entregáveis e Configurações

### Configurações do Domínio
- **Domínio**: `lab.local`
- **Nível Funcional**: Windows Server 2016

### Objetos de Política de Grupo (GPOs)
- **Iniciar Notepad no Logon**: Executa automaticamente `notepad.exe` para todos os usuários no login.
- **Restringir Acesso à Unidade C:\**: Restringe usuários padrão do domínio (não administradores) de acessar `C:\` via Explorer.

### Agendador de Tarefas
- **Nome**: `DailyReboot`
- **Agenda**: Todos os dias às 03:00.
- **Ação**: `shutdown.exe /r /t 0 /f`

### Recursos do Active Directory
- **OU**: `OU=LabUsers,DC=lab,DC=local`
- **Quantidade**: Definida pela variável `users_count` em `environments/dev/variables.tf` (padrão: `10` usuários).
- **Nomenclatura**: `user1@lab.local` até `userN@lab.local`
- **Senha Temporária**: `P@ssw0rd123!` — usuários **devem redefinir a senha no primeiro login** (boa prática de segurança).
- **Grupos**: `Domain Users` e `Remote Desktop Users`.

### Configuração das Workstations
- **Quantidade**: Definida pela variável `workstation_count` em `environments/dev/variables.tf` (padrão: `3` workstations).
- **Tipo de Instância**: Definido pela variável `workstation_instance_type` (padrão: `t3.medium`) — 2 vCPU, 4GB RAM.
- **Hostname**: Gerado automaticamente como `WORKSTATION-01`, `WORKSTATION-02`, etc. (via variável `hostname` no módulo).
- **Domain Join**: Automaticamente associadas ao domínio `lab.local` via playbook Ansible.

### Software Instalado nas Workstations (via Ansible)

| Software | Finalidade | Instalado Por |
|---|---|---|
| **Windows Updates** | Patches de segurança mais recentes | `01-baseline.yml` |
| **LAPS** | Rotação de senha do admin local (30 dias) | `02-security-hardening.yml` |
| **Windows Defender ASR** | Regras de redução de superfície de ataque | `02-security-hardening.yml` |
| **CIS Benchmark L1** | Hardening de conformidade de segurança | `02-security-hardening.yml` |
| **Prometheus Exporter** | Coleta de métricas do SO (porta 9182) | `03-monitoring.yml` |
| **Prometheus Server** | Armazenamento e consulta de métricas (porta 9090) | `03-monitoring.yml` |
| **Grafana** | Dashboards e visualização (porta 3000) | `03-monitoring.yml` |
| **Azure Arc Agent** | Gerenciamento híbrido em nuvem (opcional) | `04-azure-arc.yml` |

### Sumário de Recursos Disponíveis no Lab

| Recurso | Como Acessar |
|---|---|
| **Domain Controller (RDP)** | `mstsc /v:<ip_dc>` — usuário: `.\\Administrator` |
| **Workstations (RDP)** | Via DC ou RDP direto para IPs das workstations |
| **Prometheus Metrics** | `http://<ip_workstation>:9090` |
| **Grafana Dashboards** | `http://<ip_workstation>:3000` (admin:admin) |
| **Relatório de Usuários** | Baixado como artefato do GitHub Actions (`lab-users-report`)

### Resumo dos Playbooks Ansible

| Playbook | Descrição | Principais Recursos |
|---|---|---|
| `01-baseline.yml` | Configuração inicial | Updates, Firewall, WinRM, Fuso Horário, Logging |
| `02-security-hardening.yml` | Hardening de segurança | Defender ASR, LAPS, CIS Level 1, Políticas de Auditoria |
| `03-monitoring.yml` | Configuração de monitoramento | Prometheus Exporter, Prometheus Server, Dashboard Grafana |
| `04-azure-arc.yml` | Gerenciamento cloud híbrida | Arc Agent, Defender for Cloud, Update Management, Policy |

---

## Verificação Pós-Implantação

Conecte-se ao Domain Controller via RDP e execute os seguintes comandos PowerShell para verificar a configuração:

```powershell
# Verificar status do domínio
Get-ADDomain | Select-Object DNSRoot, NetBIOSName, DomainMode

# Verificar GPOs ativas
gpresult /r

# Verificar tarefa agendada
Get-ScheduledTask -TaskName DailyReboot | Select-Object TaskName, State, Actions

# Verificar usuários do lab
Get-ADUser -Filter * -SearchBase "OU=LabUsers,DC=lab,DC=local" |
    Format-Table Name, SamAccountName, Enabled

# Verificar computadores no domínio
Get-ADComputer -Filter * | Format-Table Name, Enabled

# Verificar métricas do Prometheus (em qualquer workstation)
Invoke-RestMethod -Uri "http://localhost:9182/metrics" | Select-Object -First 20

# Verificar conexão Azure Arc (se configurado)
& "$env:ProgramFiles\AzureConnectedMachineAgent\azcmagent.exe" show
```

---

## Recomendações para Produção

Para implantações de staging ou produção, considere os seguintes detalhes de segurança e arquitetura:
- **Isolamento de Rede**: Implante a instância EC2 em uma sub-rede privada e configure o AWS Systems Manager (SSM) para gerenciamento em vez de expor a porta RDP 3389.
- **Gerenciamento de Estado**: Use armazenamento de estado remoto com bloqueio (ex: S3 backend com DynamoDB) — já configurado em `bootstrap/`.
- **Ciclo de Vida de Recursos**: Implemente `prevent_destroy = true` em recursos críticos.
- **Gerenciamento de Segredos**: Armazene senhas no AWS Secrets Manager em vez de outputs do Terraform.
- **Logging e Monitoramento**: Habilite AWS CloudTrail, VPC Flow Logs e centralize logs do Windows Event (ex: Azure Log Analytics via Arc).
- **Alta Disponibilidade**: Implante um segundo Domain Controller em uma Zona de Disponibilidade diferente.
- **Backup**: Configure backups regulares do AD DS usando Windows Server Backup ou AWS Backup.
- **Gerenciamento de Patches**: Use Azure Update Management (via Arc) ou AWS Systems Manager Patch Manager.
