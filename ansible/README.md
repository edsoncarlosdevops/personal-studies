# Laboratório Prático de Ansible (Mac M2)

Este diretório contém os estudos práticos e playbooks desenvolvidos para aprendizado de Ansible, focando em execução isolada no Mac M2 via Docker (OrbStack), captura de output de comandos e manipulação avançada de JSON.

---

## 🛠️ Gerenciamento do Laboratório (Docker)

A melhor forma de estudar Ansible no Mac M2 sem "sujar" o sistema operacional é usando um container Ubuntu descartável/persistente.

**1. Criar e Subir o Laboratório (Modo Interativo)**
Este comando baixa uma imagem Ubuntu, instala o Ansible nela, mapeia o diretório atual do seu Mac para dentro do container e abre o terminal:
```bash
docker run -it --name lab-ansible -v $(pwd):/ansible -w /ansible ubuntu:22.04 /bin/bash
```
*(Dentro do container, execute: `apt-get update && apt-get install -y ansible vim` na primeira vez)*

**2. Sair do Laboratório**
Apenas digite `exit` no terminal do container ou feche a aba. O container será parado.

**3. Retomar o Laboratório (Sessão Salva)**
Se você saiu e quiser voltar para onde parou sem perder nada:
```bash
docker start -i lab-ansible
```

**4. Destruir o Laboratório**
Quando não precisar mais do ambiente:
```bash
docker rm -f lab-ansible
```

---

## 📁 Estrutura de Diretórios e Playbooks
Todos os códigos desenvolvidos durante o laboratório foram salvos na pasta `playbooks/`. 
Nesta pasta você encontrará os seguintes cenários práticos:

1. **`1_teste_output.yml`**: Primeiro teste capturando a saída do comando `df -h`.
2. **`2_meu_teste.yml`**: Teste de uptime focando em visualizar `stdout` versus o objeto JSON completo.
3. **`3_condicionais.yml`**: Como usar o `when` para procurar por palavras-chave (`min`, `hours`) no output.
4. **`4_read_json.yml`**: Como usar `cat` para ler um arquivo (`ultimo.json`) e o filtro `| from_json`.
5. **`5_filtro.yml`**: Uso avançado do filtro `selectattr` do Jinja2 para iterar sobre listas de dicionários e buscar a chave `ETH/USDT`.
6. **`6_auto_action.yml`**: Simulação completa (Auto-healing). Lê o json, filtra o BTC e executa um script de venda usando `when` dependendo da porcentagem negativa. Verifica o sucesso do comando pelo `rc` (Return Code).
7. **`ultimo.json`**: Arquivo de testes simulando dados de um bot de trade.

*(Para rodar qualquer um, acesse a pasta no terminal do docker e rode: `ansible-playbook <nome_do_arquivo>`)*

---

## 🚀 Meu Progresso: O que já domino
- [x] **Setup do Lab Dockerizado**: Container com volume compartilhado, mantendo meus arquivos no Mac enquanto a execução ocorre em um Linux isolado.
- [x] **Ad-Hoc Commands**: Execução imediata no terminal via `ansible -m shell`.
- [x] **Estrutura YAML Básica**: Conhecimento dos campos obrigatórios (`hosts`, `tasks`, `connection: local`).
- [x] **Captura de Logs (Register)**: Usar o `register` para guardar resultados e `debug` para exibi-los.
- [x] **Parseamento e Tratamento de JSON**: Dominado o uso de `from_json`, `selectattr` e listas no Ansible.
- [x] **Lógica de Decisão (When)**: Controlar o fluxo do script dependendo dos resultados das variáveis (Return codes e regex em stdout).

---

## 🎯 Checklist para os Próximos Passos (O que preciso aprender)
- [ ] **Módulos Nativos (Idempotência)**: Substituir o módulo `shell` por módulos especialistas como `file`, `copy` e `systemd`. Entender o poder de rodar o código 100 vezes sem alterar o estado que já está correto.
- [ ] **Loops (Laços de Repetição)**: Aprender a usar `loop` ou `with_items` para aplicar regras a várias linhas de uma lista JSON (Ex: vender todas as moedas no vermelho de uma vez).
- [ ] **Templates (Jinja2)**: Usar o módulo `template` para gerar arquivos externos complexos (como relatórios HTML ou configurações de Nginx) baseados em variáveis.
- [ ] **Variáveis Externas (`vars/`)**: Parar de hardcodar coisas nos playbooks e puxar de arquivos de configuração YAML externos.
- [ ] **Roles (Organização Escalável)**: Organizar os playbooks separando tasks, vars, templates e handlers na estrutura padrão do Ansible (Ansible Galaxy).
