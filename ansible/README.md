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

## 💻 Playbooks Desenvolvidos no Lab

Como a pasta está mapeada via volume `-v $(pwd):/ansible`, todos os playbooks criados aqui aparecem magicamente dentro do container e vice-versa.

### 1. Captura de Output Básico (`meu_teste.yml`)
Mostra como rodar um comando de shell, registrar sua saída completa (JSON) e mostrar um trecho específico usando `stdout`.

```yaml
---
- name: Testando captura de output
  hosts: localhost
  connection: local
  tasks:
    - name: Executar comando de uptime
      shell: "uptime"
      register: uptime_output

    - name: Exibir apenas a linha de texto do comando
      debug:
        msg: "O status do servidor é: {{ uptime_output.stdout }}"

    - name: Exibir o JSON completo (detalhado)
      debug:
        var: uptime_output
```
**Para rodar:** `ansible-playbook meu_teste.yml`

### 2. Leitura e Manipulação de JSON (`read_json.yml`)
Neste exemplo, simulamos a leitura de um relatório de bot de trade (`ultimo.json`) e extraímos um valor do arquivo.

*Exemplo de `ultimo.json`:*
```json
{
    "bot_name": "Trader_Alpha",
    "left_open_trades": [
        {"key": "ETH/USDT", "profit_pct": 0.29},
        {"key": "BTC/USDT", "profit_pct": -5.00}
    ]
}
```

*O Playbook:*
```yaml
---
- name: Filtrando dados de trade
  hosts: localhost
  connection: local
  tasks:
    - name: Ler o arquivo
      shell: "cat ultimo.json"
      register: json_raw

    - name: Criar objeto Ansible a partir do texto
      set_fact:
        dados: "{{ json_raw.stdout | from_json }}"

    - name: Filtrar apenas o trade de ETH usando selectattr
      set_fact:
        trade_eth: "{{ dados.left_open_trades | selectattr('key', 'equalto', 'ETH/USDT') | list }}"

    - name: Exibir resultado do filtro
      debug:
        msg: "O lucro atual de ETH é: {{ trade_eth[0].profit_pct }}%"
```

### 3. Automação Baseada em Condição (`auto_action.yml`)
Vai um passo além: procura por prejuízos na lista e toma uma ação (escrever num log) apenas se a condição for atingida.

```yaml
---
- name: Automação baseada em prejuízo
  hosts: localhost
  connection: local
  tasks:
    - name: Ler dados do bot
      shell: "cat ultimo.json"
      register: json_raw

    - name: Extrair trade de BTC de forma direta (pegando o primeiro da lista)
      set_fact:
        trade_btc: "{{ (json_raw.stdout | from_json).left_open_trades | selectattr('key', 'equalto', 'BTC/USDT') | list | first }}"

    - name: Ação Corretiva (Vender se prejuízo)
      shell: "echo 'ALERTA: BTC com queda de {{ trade_btc.profit_pct }}%. Vendendo...' > log_operacao.txt"
      when: trade_btc.profit_pct < 0

    - name: Verificar se o log de ação foi criado
      shell: "ls -la log_operacao.txt"
      register: check_file
      ignore_errors: true

    - name: Resultado da Automação
      debug:
        msg: "Ação tomada com sucesso! Verifique o log."
      when: check_file.rc == 0
```

---

## 🧠 Dicionário Prático de Conceitos Dominados

- **`connection: local`**: Diz ao Ansible para rodar comandos na própria máquina onde ele está sendo executado, ignorando conexões SSH externas.
- **`shell:`**: Módulo do Ansible que executa comandos de terminal como se fosse um usuário digitando.
- **`register:`**: Salva absolutamente tudo que aconteceu em uma tarefa (sucesso, falha, tempo, saída de tela) dentro de uma variável (JSON).
- **`debug:`**: Módulo usado para "printar" informações na tela durante a execução do Playbook (muito usado para troubleshooting).
- **`set_fact:`**: Cria uma nova variável em tempo de execução na memória do Ansible.
- **`| from_json`**: Um filtro Jinja2 que transforma uma String crua que tem formato JSON em um objeto real que o Ansible consegue navegar.
- **`selectattr`**: Filtro poderoso para buscar itens específicos dentro de uma lista baseada em um valor/chave.
- **`when:`**: A condicional clássica (IF). Se o resultado for verdadeiro, a tarefa executa. Se for falso, o Ansible pula (Skip).
- **`ignore_errors: true`**: Continua rodando o Playbook mesmo se a tarefa atual falhar (ex: um comando shell retornar erro).
- **`rc` (Return Code)**: Código de retorno nativo do Linux. Zero `0` significa sucesso. Qualquer outro número significa erro. O Ansible captura isso automaticamente.
