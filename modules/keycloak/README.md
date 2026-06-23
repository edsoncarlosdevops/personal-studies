# Keycloak

## O que e Keycloak?

Keycloak e um servidor de gerenciamento de identidade e acesso (IAM - Identity and Access Management). Ele fornece autenticacao (provar quem voce e) e autorizacao (o que voce pode fazer) para aplicacoes e servicos.

### Para que serve?

Keycloak e usado para:

1. **Login unico (SSO - Single Sign-On)** — O usuario faz login uma vez e acessa multiplas aplicacoes sem precisar se autenticar novamente. Exemplo: voce loga no Google e acessa Gmail, Drive, YouTube sem repetir a senha.

2. **Autenticacao social** — Permite login com provedores externos: Google, GitHub, Facebook, Apple. O usuario nao precisa criar uma conta nova na sua aplicacao.

3. **Protecao de APIs** — Aplicacoes backend (APIs) podem exigir um token JWT valido para processar requisicoes. O Keycloak emite e valida esses tokens.

4. **Gerenciamento centralizado de usuarios** — Um administrador pode criar, editar, desativar usuarios de todas as aplicacoes em um unico lugar. Nao precisa de um cadastro por aplicacao.

5. **Roles e permissoes** — Define quem e admin, quem e usuario comum, quem pode ver relatorios, quem pode editar dados. Tudo centralizado no Keycloak.

### Como o Keycloak funciona?

```
1. Usuario acessa aplicacao
2. Aplicacao redireciona para Keycloak (/auth)
3. Usuario faz login no Keycloak (pode ser via Google, GitHub, etc.)
4. Keycloak redireciona de volta para a aplicacao com um token JWT
5. Aplicacao valida o token (nao precisa chamar o Keycloak novamente)
6. Token contem: quem e o usuario, quais permissoes ele tem, quando expira
```

### Diferenca entre Keycloak e Vault

| Caracteristica | Keycloak | Vault |
|---------------|----------|-------|
| O que gerencia | Usuarios, sessoes, permissoes | Segredos, senhas, chaves |
| Exemplo de uso | Login no sistema, "quem pode acessar" | Senha do banco, "onde guardar a senha" |
| Protocolos | OAuth2, OpenID Connect, SAML | API REST, agent injection |
| Armazena | Usuarios, tokens, sessoes | Senhas, API keys, certificados |

**Resumo**: Keycloak = "quem voce e". Vault = "onde guardamos as credenciais".

---

## Topologia (Arquitetura)

### Componentes

```
                     [Banco de Dados (PostgreSQL)]
                              |
[Usuario] → [Navegador] → [Keycloak] → [Aplicacao]
                              |
                    [Provedor Social: Google, GitHub]
```

1. **Keycloak** — O servidor central. Processa logins, emite tokens, gerencia usuarios.
2. **PostgreSQL** — Banco de dados onde o Keycloak armazena: usuarios, realms, clients, sessoes.
3. **Provedor Social (opcional)** — Google, GitHub, Facebook para login social.

### Fluxo de Autenticacao (Authorization Code Flow)

Este e o fluxo mais comum para aplicacoes web:

```
1. Usuario clica em "Login" na aplicacao
2. Aplicacao redireciona para: keycloak:8080/realms/meurealm/protocol/openid-connect/auth?client_id=minha-app&redirect_uri=http://meusite/callback
3. Keycloak mostra tela de login (ou redireciona para Google/GitHub)
4. Usuario faz login
5. Keycloak redireciona de volta para a aplicacao com um codigo (code)
6. Aplicacao troca o codigo por um token (POST para /token)
7. Aplicacao usa o token para acessar recursos
8. Quando o token expira, a aplicacao usa o refresh token para obter um novo
```

---

## Conceitos Fundamentais

### Realm

Um realm e como um "espaco isolado" dentro do Keycloak. Cada realm tem seus proprios usuarios, clients e configuracoes.

```
Keycloak
├── Realm: meurealm (minha aplicacao)
│   ├── Usuarios: joao, maria, admin
│   ├── Clients: api-pedidos, frontend-web
│   └── Roles: admin, usuario, leitor
├── Realm: outro-realm (outra aplicacao)
│   ├── Usuarios: pedro, ana
│   ├── Clients: app-financeiro
│   └── Roles: gerente, operador
└── Realm: master (apenas para administracao)
```

**IMPORTANTE**: NUNCA use o realm `master` para suas aplicacoes. Crie um realm especifico (ex: `meurealm`). O realm master e apenas para configuracao global.

### Client

Um client e a aplicacao que usa o Keycloak para autenticacao. Pode ser:

- **Aplicacao web** (ex: React, Angular, Vue) — usa Authorization Code Flow
- **API backend** (ex: Node.js, Python, Java) — valida tokens, usa Client Credentials
- **Aplicacao mobile** (ex: iOS, Android) — usa PKCE Flow

Cada client tem:
- `client_id`: identificador unico
- `client_secret`: senha do client (para aplicacoes confidenciais)
- `redirect_uris`: URLs para onde o Keycloak redireciona apos o login
- `access_type`: `confidential` (com secret) ou `public` (sem secret, para SPAs)

### Token JWT

O token que o Keycloak emite e um JWT (JSON Web Token). Ele contem:

```json
{
  "sub": "abc123",           // ID do usuario
  "preferred_username": "joao",
  "email": "joao@email.com",
  "realm_access": {
    "roles": ["admin"]       // permissoes do usuario
  },
  "iat": 1687459200,          // emitido em
  "exp": 1687462800           // expira em (1 hora)
}
```

A aplicacao pode validar este token sem consultar o Keycloak (usando a chave publica em `/certs`).

### Roles

Roles definem permissoes. Existem 2 tipos:

1. **Realm Role**: permissao global (ex: `admin`, `usuario`, `leitor`)
2. **Client Role**: permissao especifica para um client (ex: `api-pedidos:gerenciar-pedidos`)

---

## Instalacao

```bash
# Adicionar repositorio
helm repo add bitnami https://charts.bitnami.com/bitnami

# Instalar Keycloak com PostgreSQL
helm install keycloak bitnami/keycloak -f config/values.yaml -n keycloak --create-namespace
```

### Verificar instalacao

```bash
# Pods (deve ter 2: keycloak + postgresql)
kubectl get pods -n keycloak

# Logs do Keycloak
kubectl logs -n keycloak deploy/keycloak --tail=50
# Deve aparecer: "Keycloak started on http://0.0.0.0:8080"
```

---

## Acesso ao Console Admin

```bash
# Port-forward para acessar localmente
kubectl port-forward -n keycloak svc/keycloak 8080:8080
```

Acesse: http://localhost:8080

### Primeiro Login

1. Clique em "Administration Console"
2. Usuario: `admin`
3. Senha: `admin` (definida no `values.yaml` em `auth.adminPassword`)

**IMPORTANTE**: Mude a senha do admin imediatamente apos o primeiro login.

---

## Configuracao Inicial (Passo a Passo)

### 1. Criar um Realm

1. No menu lateral, clique em "Create Realm"
2. Nome do Realm: `meurealm`
3. Clique em "Create"

### 2. Criar um Usuario

1. Dentro do realm, va em "Users" -> "Add user"
2. Username: `joao`
3. Email: `joao@email.com`
4. Clique em "Create"
5. Va na aba "Credentials"
6. Defina a senha: `senha123`
7. Desabilite "Temporary" (senao o usuario precisa trocar a senha no primeiro login)

### 3. Criar um Client (para sua aplicacao)

1. Va em "Clients" -> "Create client"
2. Client ID: `minha-app`
3. Client authentication: ON (gera um client_secret)
4. Standard flow: ON (Authorization Code Flow)
5. Valid redirect URIs: `http://localhost:3000/*` (URL da sua aplicacao)
6. Clique em "Save"

### 4. Testar o Fluxo

Acesse no navegador:

```
http://localhost:8080/realms/meurealm/protocol/openid-connect/auth?client_id=minha-app&redirect_uri=http://localhost:3000/callback&response_type=code&scope=openid
```

Se funcionar, o Keycloak mostrara a tela de login.

---

## Integracao com Aplicacao

### Exemplo com React (biblioteca keycloak-js)

```javascript
import Keycloak from 'keycloak-js';

const keycloak = new Keycloak({
  url: 'http://keycloak.keycloak.svc.cluster.local:8080',
  realm: 'meurealm',
  clientId: 'minha-app',
});

// Iniciar login
await keycloak.init({ onLoad: 'login-required' });

// Token JWT (enviar no header Authorization)
const token = keycloak.token;
// Authorization: Bearer <token>

// Informacoes do usuario
console.log(keycloak.tokenParsed.preferred_username);
console.log(keycloak.tokenParsed.email);
```

### Exemplo com Python (FastAPI + python-jose)

```python
from fastapi import FastAPI, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwk, jwt
from jose.utils import base64url_decode
import requests

app = FastAPI()
security = HTTPBearer()

# Obter chave publica do Keycloak
certs = requests.get(
    "http://keycloak.keycloak.svc.cluster.local:8080/realms/meurealm/protocol/openid-connect/certs"
).json()

def validate_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    try:
        # Validar token JWT (verifica assinatura e expiracao)
        payload = jwt.decode(token, certs, algorithms=["RS256"])
        return payload
    except Exception as e:
        raise HTTPException(status_code=401, detail="Token invalido")

@app.get("/api/protegido")
def endpoint_protegido(user=Depends(validate_token)):
    return {"message": f"Ola, {user['preferred_username']}"}
```

---

## Valores de Configuracao (values.yaml)

O arquivo `config/values.yaml` contem todas as opcoes comentadas. Abaixo, as principais:

### `postgresql`

Keycloak PRECISA de um banco de dados PostgreSQL. Ele nao funciona com SQLite (como outras aplicacoes fazem em lab).

```
postgresql:
  enabled: true
  auth:
    username: keycloak
    password: keycloak
    database: keycloak
```

- `enabled: true`: instala o PostgreSQL como subchart. Para producao, desabilite (`false`) e configure `externalDatabase` apontando para um RDS/CloudSQL.
- `auth`: usuario, senha e nome do banco. O Keycloak usa esses valores para se conectar.

### `auth.adminUser` e `auth.adminPassword`

Credenciais do usuario administrador do Keycloak.

```
auth:
  adminUser: admin
  adminPassword: admin
```

Use `adminPassword: admin` apenas em lab. Em producao, use uma senha forte de 20+ caracteres.

### `extraEnvVars`

Variaveis de ambiente para configurar o Keycloak. As principais:

**KC_PROXY**: define como o Keycloak lida com proxies.

```
- name: KC_PROXY
  value: edge
```

Opcoes:
- `edge`: Keycloak confia no proxy (terminacao TLS no ingress). Recomendado para cluster K8s.
- `reencrypt`: TLS do proxy ate o pod.
- `passthrough`: TLS direto, sem proxy.

**KC_CACHE**: tipo de cache distribuido.

```
- name: KC_CACHE
  value: ispn
```

Opcoes:
- `local`: cache local. NAO use se tiver mais de 1 replica.
- `ispn`: Infinispan cache distribuido. Use se tiver 2+ replicas.

**KC_CACHE_STACK**: pilha de descoberta do Infinispan.

```
- name: KC_CACHE_STACK
  value: kubernetes
```

- `kubernetes`: descobre pods via DNS.
- `tcp`: enderecos fixos.
- `udp`: multicast (pode nao funcionar em cloud).

---

## Troubleshooting

### Keycloak nao inicia (CrashLoopBackOff)

Causa comum: PostgreSQL nao esta pronto, ou a senha esta errada.

```bash
# Ver logs
kubectl logs -n keycloak deploy/keycloak --tail=50
# Mensagem tipica: "connection to database at postgresql:5432 failed"

# Verificar se o PostgreSQL esta rodando
kubectl get pods -n keycloak -l app.kubernetes.io/name=postgresql

# Testar conexao manual
kubectl exec -n keycloak deploy/keycloak -- nc -zv postgresql 5432
```

### "Invalid parameter: redirect_uri"

A URL de redirecionamento configurada no Client nao corresponde a URL real da aplicacao.

```
# Erro: http://localhost:3000/callback nao esta na lista de redirect URIs
# Solucao: va em Clients > sua-app > Settings > Valid Redirect URIs
# Adicione: http://localhost:3000/*
```

### "Token is not active" ou "Token expired"

O token expirou. A aplicacao precisa usar o refresh token para obter um novo.

```javascript
// Exemplo com keycloak-js
keycloak.onTokenExpired = () => {
  keycloak.updateToken(30) // renova se expirar em menos de 30s
    .then(() => {
      console.log('Token renovado');
    });
};
```

### Login retorna "Unknown error"

Causa comum: o Client nao tem a URL correta configurada, ou o fluxo de autenticacao nao esta habilitado.

```
# Va em Clients > sua-app > Settings
# Verifique:
# - Standard Flow Enabled: ON
# - Valid Redirect URIs: contem a URL da sua aplicacao
# - Web Origins: contem a URL da sua aplicacao (ou * para lab)
```

---

## Seguranca

### Recomendacoess para Producao

1. **NUNCA use o realm master** para aplicacoes. Crie realms especificos.
2. **Use senhas fortes**: adminUser/adminPassword e client_secret com 20+ caracteres.
3. **Banco externo gerenciado**: use RDS (AWS), CloudSQL (GCP) ou Azure Database for PostgreSQL.
4. **HTTPS obrigatorio**: configure TLS no ingress. Keycloak envia tokens pela rede, NUNCA sem criptografia.
5. **Token expiration**: defina expiracao curta (15-30 minutos para acesso, 8 horas para refresh).
6. **Rate limiting**: proteja o endpoint de login contra bruteforce.
7. **Auditoria**: habilite logs de eventos de login (Users > Events > Config).

---

## Referencias

- [Documentacao oficial do Keycloak](https://www.keycloak.org/documentation)
- [Keycloak no Bitnami](https://github.com/bitnami/charts/tree/main/bitnami/keycloak)
- [OpenID Connect Explained](https://openid.net/developers/how-connect-works/)
- [JWT.io](https://jwt.io/) — debug de tokens JWT
