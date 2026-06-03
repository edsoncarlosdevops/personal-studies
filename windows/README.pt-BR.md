# Provisionamento de Domain Controller Windows e Workstations na AWS

Este projeto automatiza o provisionamento e configuração de um **Domain Controller Windows Server 2022** com **múltiplas workstations parametrizadas** na AWS utilizando **Terraform**, **Ansible** e **PowerShell**. Inclui ciclo de configuração pós-instalação totalmente automatizado, hardening de segurança, monitoramento, gerenciamento de cloud híbrida e pipelines de integração/entrega contínua (CI/CD).

---

## Arquitetura

### Infraestrutura AWS (Terraform)
- **VPC**: Virtual Private Cloud dedicada com sub-rede pública, internet gateway e tabelas de roteamento para tráfego de entrada e saída.
- **Domain Controller**: Windows Server 2022 (t3.large) provisionado com Active Directory Domain Services.
- **Workstations**: Windows Server 2022 (t3.medium) provisionadas via count — totalmente parametrizado para escalabilidade.
- **S3 Bucket**: Recurso de armazenamento seguro com versionamento, políticas de ciclo de vida e criptografia SSE-KMS com chaves gerenciadas pelo cliente.
- **Security Group**: Restringe RDP (porta 3389) e WinRM (porta 5985) dinamicamente ao IP público do host de implantação (obtido em tempo real via api.ipify.org).

### Configuração do SO (PowerShell + Ansible)
- **Active Directory (PowerShell)**: Instalação automatizada do AD DS e promoção de floresta usando ciclo de duas fases com RunOnce.
- **Configuração das Workstations (Ansible)**: 4 playbooks para baseline, hardening de segurança, monitoramento e Azure Arc.

---

## Decisões de Design

- **Provisionamento Agentless em Duas Fases**: PowerShell nativo combinado com a chave de registro RunOnce do Windows para promoção do AD DS. Isso elimina a necessidade de ferramentas externas de gerenciamento de configuração, enquanto navega com sucesso pela reinicialização obrigatória do sistema durante a promoção do Active Directory.
- **Ansible para Configuração Pós-Deploy**: Após o DC estar pronto, o Ansible (via WinRM) configura as workstations com atualizações, políticas de segurança, agentes de monitoramento e extensões de cloud — permitindo uma clara separação de responsabilidades (Terraform = infra, Ansible = config).
- **Restrição Dinâmica de IP**: Em vez de expor RDP (porta 3389) para 0.0.0.0/0, a configuração obtém dinamicamente o IP público do operador via api.ipify.org, restringindo o tráfego de entrada especificamente ao administrador autorizado.
- **Varredura Automática de Políticas e Segurança**: Checkov (SAST) e Open Policy Agent (OPA) incluídos diretamente no ciclo de vida de pull requests do CI/CD. Isso garante que verificações de conformidade e varreduras de segurança sejam executadas antes da modificação dos recursos.
- **Ciclo de Vida Seguro de Senhas**: Uso do provider random_password do Terraform para gerar as senhas do Administrador e DSRM (Modo de Segurança) programaticamente, exibindo-as seguramente via outputs em vez de codificá-las nos scripts de configuração.
- **Escalonamento de Workstations Baseado em Count**: Workstations são criadas usando o meta-parâmetro count do Terraform, controlado por uma única variável (workstation_count). Sem duplicação de código — adicione 3 ou 30 workstations alterando apenas um número.

---

## Workflows CI/CD (GitHub Actions)

O repositório fornece pipelines automatizados em .github/workflows/ para gerenciar qualidade de código, segurança e implantação:

### 1. Terraform Validate (terraform-validate.yaml)
- **Gatilho**: Automático em push e pull_request para a branch main.
- **Jobs**:
  - **Validate**: Formata (terraform fmt -check), inicializa sem backend (terraform init -backend=false) e executa validação estática (terraform validate).
  - **Security Scan**: Utiliza Checkov para executar testes de segurança estáticos (SAST) nas configurações do Terraform.
  - **OPA Policy Check**: Executa verificações do Open Policy Agent (OPA) para garantir conformidade com as políticas de infraestrutura da organização.

### 2. Terraform Apply (terraform-apply.yaml)
- **Gatilho**: Manual (workflow_dispatch).
- **Jobs**:
  - **Plan**: Gera e envia o plano de execução (tfplan) como artefato.
  - **Apply**: Baixa o artefato e aplica as alterações. Utiliza GitHub Secrets para autenticação AWS.
  - **Relatório do Lab**: Gera um artefato HTML (lab-users-report) com a lista completa de usuários e workstations provisionados.
  - **Sumário**: Escreve os parâmetros de saída da implantação diretamente no sumário da execução do GitHub Actions.

### 3. Terraform Destroy (terraform-destroy.yaml)
- **Gatilho**: Manual (workflow_dispatch).
- **Jobs**:
  - **Destroy**: Remove todos os recursos provisionados pelo workspace para evitar custos ativos.

---

## Como Funciona o Ciclo de Automação

A configuração do SO é executada de forma completamente autônoma, utilizando o UserData da EC2 e as configurações de registro RunOnce do Windows:

### Fase 1: Boot e Instalação do AD DS
- A instância inicializa e executa o script configure-ad.ps1 via UserData.
- O script instala o papel AD DS e promove o servidor a Domain Controller para o domínio lab.local.
- O processo de promoção aciona uma reinicialização obrigatória do sistema.
- Antes de reiniciar, uma chave de registro é adicionada em HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce para retomar a execução do script.

### Fase 2: Configuração Pós-Reinicialização
- Após a reinicialização, o sistema faz login automaticamente como Administrador e retoma a execução via RunOnce.
- O script detecta que o papel AD DS está ativo e prossegue com:
  - Criação da OU alvo (OU=LabUsers,DC=lab,DC=local).
  - Provisionamento de usuários em lote (user1@lab.local até userN@lab.local).
  - Criação e vinculação de GPOs (inicialização do Notepad e restrição da unidade C:\ ).
  - Agendamento de tarefa de reinicialização diária às 03:00.
  - Finalização da segurança do sistema e remoção da chave RunOnce.

### Fase 3: Configuração Pós-Provisionamento (Ansible)
Após o DC e as workstations serem provisionados pelo Terraform, o Ansible configura as workstations:
- **Baseline**: Windows Updates, regras de Firewall, ajuste WinRM, fuso horário.
- **Hardening de Segurança**: Windows Defender (regras ASR), instalação do LAPS, CIS Benchmark Level 1, políticas de auditoria avançadas.
- **Monitoramento**: Prometheus Windows Exporter, Prometheus Server, dashboard Grafana.
- **Azure Arc**: Connected Machine Agent, Defender for Cloud, Update Management, Azure Policy.

---

## Instruções de Implantação

### Opção A: Implantação Local

```bash
# 1. Inicializar Backend e Providers
cd environments/dev
terraform init

# 2. (Opcional) Personalizar quantidade de workstations
# Edite terraform.tfvars ou use -var:
# workstation_count = 5
# users_count = 15

# 3. Aplicar Configurações
terraform apply -auto-approve

# 4. Gerar inventário do Ansible
terraform output -raw ansible_inventory > ../../ansible/inventory/dev.yml

# 5. Configurar workstations com Ansible
cd ../../ansible
ansible-playbook playbooks/01-baseline.yml
ansible-playbook playbooks/02-security-hardening.yml
ansible-playbook playbooks/03-monitoring.yml
```

### Opção B: Implantação via CI/CD

1. Configure as credenciais AWS como GitHub Secrets.
2. Execute o workflow Terraform Apply manualmente na aba GitHub Actions.
3. Após a conclusão, baixe o artefato lab-users-report para a lista de usuários.
4. Acesse os detalhes dos outputs no sumário da execução do GitHub.

---

## Credenciais e Acesso RDP

### Outputs do Terraform

| Comando | Descrição |
|---|---|
| terraform output admin_password | Senha do Administrador local |
| terraform output safe_mode_password | Senha DSRM do Active Directory |
| terraform output dc_public_ip | IP público do Domain Controller |
| terraform output workstation_ips | IPs públicos de todas as workstations |
| terraform output lab_users | Lista completa de usuários do AD |
| terraform output ansible_inventory | Inventário YAML para o Ansible |

### Acesso RDP

```bash
terraform output -raw dc_public_ip
mstsc /v:<IP_DO_DC>
# Usuário: .\Administrator
# Senha: terraform output -raw admin_password
```

### Usuários do Lab

| Parâmetro | Valor |
|---|---|
| Usuário Admin | .\Administrator |
| Domínio | lab.local |
| Usuários do Lab | user1@lab.local até userN@lab.local |
| Senha Padrão | P@ssw0rd123! |
| Grupos | Domain Users, Remote Desktop Users |
| OU | OU=LabUsers,DC=lab,DC=local |

### Acesso ao Monitoramento

| Serviço | URL | Credenciais |
|---|---|---|
| Prometheus | http://<IP_WORKSTATION>:9090 | - |
| Grafana | http://<IP_WORKSTATION>:3000 | admin:admin |
| Windows Exporter | http://<IP_WORKSTATION>:9182/metrics | - |

---

## Estrutura do Projeto

```
ansible/                       # Playbooks Ansible (WinRM)
environments/                  # Bootstrap + Dev
modules/                       # VPC, S3, SG, Windows Server
policies/                      # OPA compliance
scripts/                       # configure-ad.ps1 + setup.sh
.github/workflows/             # CI/CD pipelines
```

---

## Entregáveis e Configurações

- **Domínio**: lab.local (Nível Funcional: Windows Server 2016)
- **GPOs**: Notepad no logon + Restrição C:\
- **Tarefa Agendada**: DailyReboot às 03:00
- **Usuários**: user1 até userN em OU=LabUsers
- **Playbooks**: 01-baseline, 02-security, 03-monitoring, 04-azure-arc

---

## Verificação Pós-Implantação

```powershell
Get-ADDomain | Select-Object DNSRoot, NetBIOSName, DomainMode
gpresult /r
Get-ScheduledTask -TaskName DailyReboot
Get-ADUser -Filter * -SearchBase "OU=LabUsers,DC=lab,DC=local"
Get-ADComputer -Filter *
```

---

## Recomendações para Produção

- Isolamento de Rede: Sub-rede privada + SSM em vez de RDP público
- State Remoto: S3 + DynamoDB (já configurado)
- Secrets: AWS Secrets Manager em vez de outputs
- HA: Segundo DC em outra AZ
- Backup: Windows Server Backup ou AWS Backup

---

<div align="center">
  <sub>Feito com ☕ por Edson Carlos</sub>
</div>
