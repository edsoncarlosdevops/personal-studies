# Vault

## O que e Vault?

HashiCorp Vault e um gerenciador de segredos (secrets manager). Ele armazena, controla acesso e faz rotacao de dados sensiveis como senhas, tokens de API, certificados TLS e chaves de criptografia.

### Para que serve?

Vault e usado para:

1. **Armazenar senhas com seguranca** — Em vez de colocar a senha do banco no codigo fonte ou em um arquivo `.env`, a aplicacao busca a senha no Vault no momento em que precisa.

2. **Girar senhas automaticamente (rotation)** — Vault pode gerar senhas temporarias para o banco de dados. Depois de X minutos, a senha expira e ninguem mais consegue usa-la.

3. **Emitir certificados TLS dinâmicos** — Vault pode gerar certificados TLS sob demanda, sem precisar comprar ou renovar manualmente.

4. **Criptografar dados** — Vault fornece uma API de criptografia. Voce envia dados, ele criptografa com uma chave que nunca sai do Vault.

5. **Auditoria** — Todo acesso ao Vault e logado: quem acessou, o que acessou, quando.

### Como o Vault funciona?

```
Aplicacao → Autentica (JWT, Token, K8s Auth) → Vault

Se autorizado → Vault descriptografa o segredo → Retorna para aplicacao

Aplicacao usa o segredo (ex: conecta no banco)

O segredo tem tempo de vida (TTL). Depois, expira e precisa ser renovado.
```

Diferenca para um arquivo `.env`:

| Caracteristica | .env | Vault |
|---------------|------|-------|
| Onde fica a senha | No arquivo, em texto plano | Criptografada no Vault |
| Quem pode acessar | Qualquer um com acesso ao arquivo | Apenas quem tem permissao no Vault |
| Rotacao | Manual (editar arquivo) | Automatica (TTL) |
| Auditoria | Nao | Sim — cada acesso e logado |
| Vazamento em Git | Facil (commita sem querer) | Impossivel (senha nunca esta no codigo) |

---

## Diferenca entre Vault e Keycloak

Muita gente confunde os dois. A diferenca e simples:

| | Vault | Keycloak |
|---|-------|----------|
| **O que faz** | Gerencia segredos (senhas, chaves) | Gerencia identidade (login, usuarios) |
| **Pergunta que responde** | "Onde guardo a senha do banco?" | "Quem esta fazendo login?" |
| **Exemplo tipico** | App busca senha do PostgreSQL no Vault | Usuario faz login com Google via Keycloak |
| **Protocolo** | API REST, Agent Injection | OAuth2, OpenID Connect, SAML |

**Resumo**: Vault = cofre de senhas. Keycloak = porteiro que decide quem entra.

---

## Conceitos Fundamentais

### Sealed vs Unsealed

Quando o Vault inicia, ele esta "sealed" (selado/bloqueado). Ele nao responde a nenhuma requisicao ate ser desbloqueado.

```
Vault inicia → SEALED (nao aceita requisicoes)
                    |
            Operador executa: vault operator unseal <chave>
                    |
            (repetir 3 vezes com chaves diferentes)
                    |
            Vault → UNSEALED (pronto para uso)
```

Por que isso existe? Para que mesmo se alguem roubar o disco do Vault, nao consiga ler os segredos sem as chaves de unseal.

**No modo standalone**: apos cada restart do pod, voce precisa fazer unseal manualmente.

**No modo HA com Raft**: o chart pode fazer auto-unseal, mas e menos seguro.

### Seal (Auto-Unseal via KMS)

Em producao, configure auto-unseal usando um KMS (AWS KMS, GCP Cloud KMS, Azure Key Vault). O Vault delega o desbloqueio para o KMS da nuvem.

```
Vault inicia → Pede para o AWS KMS desbloquear
                          |
                  KMS verifica a chave
                          |
                  Vault → UNSEALED
```

Vantagem: Nao precisa de operador humano para desbloquear apos restart.

### Token Root

O token root e como se fosse a "senha de administrador" do Vault. Com ele, voce pode fazer TUDO. Por isso:

- NUNCA compartilhe o token root
- NUNCA use o token root no dia a dia (crie tokens com permissoes limitadas)
- NUNCA commite o token root no Git
- Guarde em um cofre fisico ou gerenciador de senhas

### Paths (Caminhos)

No Vault, segredos sao organizados em paths (caminhos), como se fossem pastas:

```
secret/                        # engine kv (chave-valor)
├── minha-app/
│   ├── database               # "senha do banco da minha-app"
│   └── api-token              # "token da API externa"
├── outra-app/
│   └── credentials
pki/                           # engine pki (certificados)
├── issue/
│   └── minha-app              # "emite certificado TLS"
database/                      # engine database (credenciais rotativas)
├── creds/
│   └── postgres               # "senha temporaria do PostgreSQL"
```

---

## Instalacao

```bash
# Adicionar repositorio da HashiCorp
helm repo add hashicorp https://helm.releases.hashicorp.com

# Instalar Vault em modo standalone
helm install vault hashicorp/vault -f config/values.yaml -n vault --create-namespace
```

### Verificar instalacao

```bash
kubectl get pods -n vault
# Deve aparecer: vault-0 (1/1 Running)

kubectl logs -n vault vault-0
# Deve aparecer: "Vault server started"
```

---

## Inicializacao do Vault (Passo a Passo)

Apos a instalacao, o Vault esta sealed. Voce precisa inicializa-lo e desbloquea-lo.

### 1. Inicializar (gera chaves de unseal + token root)

```bash
kubectl exec -n vault vault-0 -- vault operator init
```

Saida esperada (exemplo):

```
Unseal Key 1: abc123... (guarde isso)
Unseal Key 2: def456... (guarde isso)
Unseal Key 3: ghi789... (guarde isso)
Unseal Key 4: jkl012... (guarde isso)
Unseal Key 5: mno345... (guarde isso)

Initial Root Token: hvs.xxxxx... (guarde COM A VIDA)
```

**IMPORTANTE**: O Vault gera 5 chaves, mas apenas 3 sao necessarias para desbloquear (threshold = 3). Isso significa que se voce perder 2 chaves, ainda consegue desbloquear. Se perder 3, nunca mais consegue acessar.

### 2. Desbloquear (unseal)

Repita 3 vezes com chaves diferentes:

```bash
kubectl exec -n vault vault-0 -- vault operator unseal <Unseal Key 1>
kubectl exec -n vault vault-0 -- vault operator unseal <Unseal Key 2>
kubectl exec -n vault vault-0 -- vault operator unseal <Unseal Key 3>
```

A cada comando, a saida mostra:
```
Sealed: true   (ainda bloqueado)
Sealed: true   (ainda bloqueado)
Sealed: false  (desbloqueado!)
```

### 3. Login com token root

```bash
kubectl exec -n vault vault-0 -- vault login <Initial Root Token>
# Resposta: Success! You are now authenticated.
```

### 4. Acessar a UI

```bash
kubectl port-forward -n vault svc/vault 8200:8200
```

Acesse: http://localhost:8200

Token: cole o `Initial Root Token` no campo.

---

## Fluxo Basico (Armazenar e Ler Segredos)

### Via CLI (dentro do pod)

```bash
# Entrar no pod
kubectl exec -n vault -it vault-0 -- sh

# Autenticar (se nao estiver autenticado)
vault login <token-root>

# Ativar o secrets engine KV (chave-valor) versao 2
vault secrets enable -path=secret kv-v2

# Armazenar um segredo
vault kv put secret/minha-app/database username=admin password=senha-segura

# Ler o segredo
vault kv get secret/minha-app/database
# Saida:
# ====== Data ======
# Key         Value
# ---         -----
# password    senha-segura
# username    admin

# Listar segredos
vault kv list secret/minha-app/
```

### Via UI (navegador)

1. Acesse http://localhost:8200
2. Faca login com o token root
3. Va em "Secrets Engines" -> "Enable new engine" -> KV -> Path: `secret`
4. Va em `secret/` -> "Create secret" -> Path: `minha-app/database`
5. Adicione os campos: `username` = `admin`, `password` = `senha-segura`

### Via API (curl)

```bash
# Autenticar e obter token
TOKEN=$(curl -s -X POST http://localhost:8200/v1/auth/token/lookup \
  -H "X-Vault-Token: hvs.xxxxx" | jq -r '.data.id')

# Escrever segredo
curl -s -X POST http://localhost:8200/v1/secret/data/minha-app/database \
  -H "X-Vault-Token: $TOKEN" \
  -d '{"data": {"username": "admin", "password": "senha-segura"}}'

# Ler segredo
curl -s http://localhost:8200/v1/secret/data/minha-app/database \
  -H "X-Vault-Token: $TOKEN" | jq '.data.data'
```

---

## Integracao com Aplicacao (Vault Agent Sidecar)

O Vault pode injetar segredos diretamente nos pods das aplicacoes, sem que a aplicacao precise saber que o Vault existe.

### Como funciona

```
1. Pod da aplicacao e criado com annotations especiais
2. Vault Agent Injector (webhook) detecta as annotations
3. Webhook adiciona um sidecar (vault-agent) ao pod
4. vault-agent autentica no Vault e busca os segredos
5. vault-agent escreve os segredos em arquivos dentro do pod
6. Aplicacao le os arquivos (ex: /vault/secrets/database)
```

### Configuracao no pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: minha-app
  annotations:
    # Habilita a injecao do sidecar
    vault.hashicorp.com/agent-inject: "true"
    # Role que o pod vai usar para autenticar
    vault.hashicorp.com/role: "minha-app"
    # Injeta o segredo "database" em /vault/secrets/database
    vault.hashicorp.com/agent-inject-secret-database: "secret/data/minha-app/database"
    # Template para formatar o arquivo (opcional)
    vault.hashicorp.com/agent-inject-template-database: |
      {{- with secret "secret/data/minha-app/database" -}}
      export DB_USERNAME={{ .Data.data.username }}
      export DB_PASSWORD={{ .Data.data.password }}
      {{- end -}}
spec:
  containers:
    - name: minha-app
      image: minha-app:latest
      # A aplicacao le as variaveis do arquivo
      command: ["sh", "-c", "source /vault/secrets/database && npm start"]
```

### Autenticacao Kubernetes (Kubernetes Auth)

Para o vault-agent se autenticar, voce precisa configurar o Kubernetes Auth no Vault:

```bash
# Entrar no pod do Vault
kubectl exec -n vault -it vault-0 -- sh

# Ativar o auth method kubernetes
vault auth enable kubernetes

# Configurar o endereco do cluster K8s
vault write auth/kubernetes/config \
  kubernetes_host=https://${KUBERNETES_PORT_443_TCP_ADDR}:443

# Criar uma role que mapeia service account para politica
vault write auth/kubernetes/role/minha-app \
  bound_service_account_names=minha-app \
  bound_service_account_namespaces=default \
  policies=minha-app-policy \
  ttl=1h
```

---

## Valores de Configuracao (values.yaml)

O arquivo `config/values.yaml` contem todas as opcoes comentadas. Abaixo, as principais:

### `mode`

Define o modo de operacao do Vault.

```
mode: standalone
```

Opcoes:
- `dev`: apenas para testar APIs, sem persistencia, ja inicia unsealed. NAO use em producao.
- `standalone`: um pod, requer unseal manual. Use para lab.
- `ha`: multiplos pods com Raft. Alta disponibilidade. Use para producao.

### `server.standalone.config`

Configuracao do Vault em modo standalone.

```
server:
  standalone:
    enabled: true
    config: |
      ui = true
      listener "tcp" {
        address = "[::]:8200"
        tls_disable = true
      }
      storage "file" {
        path = "/vault/data"
      }
```

- `ui = true`: habilita a interface web.
- `listener "tcp"`: endereco e porta que o Vault escuta.
- `tls_disable = true`: desabilita TLS (o TLS e terminado no Ingress em cluster K8s).
- `storage "file"`: armazena dados em arquivos no disco local.

### `server.ha.raft.config`

Para modo HA com Raft:

```
storage "raft" {
  path = "/vault/data"
  node_id = "vault-0"
  retry_join {
    leader_api_addr = "http://vault-active:8200"
  }
}
```

- `raft`: protocolo de consenso (igual ao Consul etcd). Replica dados entre pods.
- `retry_join`: quando o pod inicia, tenta se juntar ao cluster Raft.
- `vault-active`: servico que aponta sempre para o leader.

### `auto.enabled`

Auto-unseal via init container.

```
auto:
  enabled: false
```

Quando ativado, o chart coloca um init container que le as chaves de unseal de um ConfigMap. Isso e pratico para lab, mas REDUZ a seguranca porque as chaves ficam em texto plano no ConfigMap.

---

## Troubleshooting

### Vault sealed apos restart

No modo standalone, toda vez que o pod reinicia, o Vault volta ao estado sealed.

```bash
# Verificar se esta sealed
kubectl exec -n vault vault-0 -- vault status
# Se "Sealed: true", fazer unseal

# Unseal (3 vezes com chaves diferentes)
kubectl exec -n vault vault-0 -- vault operator unseal <chave-1>
kubectl exec -n vault vault-0 -- vault operator unseal <chave-2>
kubectl exec -n vault vault-0 -- vault operator unseal <chave-3>
```

### "Error making API request: Put http://localhost:8200/v1/sys/seal/unseal: EOF"

O Vault nao esta rodando ou nao esta pronto.

```bash
kubectl logs -n vault vault-0 --tail=20
# Verificar se ha erro no startup
```

### "Vault is sealed" ao tentar ler/escrever

Voce tentou acessar o Vault antes de desbloquear.

```bash
# Verificar status
kubectl exec -n vault vault-0 -- vault status

# Se sealed, fazer unseal (como acima)
```

### Perdi o token root

Se perder o token root, voce precisa gerar outro usando as chaves de unseal:

```bash
kubectl exec -n vault vault-0 -- vault operator generate-root -init
# Isso gera um one-time password (OTP)

kubectl exec -n vault vault-0 -- vault operator generate-root -generate-root <chave-1>
kubectl exec -n vault vault-0 -- vault operator generate-root -generate-root <chave-2>
kubectl exec -n vault vault-0 -- vault operator generate-root -generate-root <chave-3>

kubectl exec -n vault vault-0 -- vault operator generate-root -decode <encoded-token> <otp>
```

**NOTA**: Esse processo e complexo de proposito. Se fosse facil, qualquer um com as chaves conseguiria um token root.

---

## Seguranca

### Recomendacoes para Producao

1. **NUNCA perca as chaves de unseal** — Sem elas, voce nunca mais acessa os segredos.
2. **NUNCA perca o token root** — Sem ele, nao consegue configurar o Vault.
3. **NUNCA commite chaves ou tokens no Git** — Nem em repositorios privados.
4. **Guarde as chaves separadamente** — Cada chave com uma pessoa diferente (ex: 5 pessoas, cada uma guarda uma chave).
5. **Use auto-unseal com KMS** em producao (AWS KMS, GCP Cloud KMS).
6. **Use banco de dados externo** para o storage do Vault (RDS, CloudSQL) — disco local e fragil.
7. **Configure politicas minimas** — Cada aplicacao so ve seus proprios segredos, nunca os das outras.
8. **Habilite auditoria** — `vault audit enable file file_path=/vault/logs/audit.log`

---

## Referencias

- [Documentacao oficial do Vault](https://developer.hashicorp.com/vault/docs)
- [Vault Helm Chart](https://github.com/hashicorp/vault-helm)
- [Vault Agent Injector](https://developer.hashicorp.com/vault/docs/platform/k8s/injector)
- [Vault Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets)
