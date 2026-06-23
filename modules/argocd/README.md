# ArgoCD

## O que e ArgoCD?

ArgoCD e uma ferramenta **GitOps** para Kubernetes. GitOps significa que o **Git e a unica fonte da verdade** para o estado do cluster. Voce descreve o que quer (deployments, services, configmaps) em arquivos YAML no Git, e o ArgoCD mantem o cluster identico ao que esta no repositorio.

### Para que serve?

1. **Deploy automatico** - Quando voce faz um commit no Git, o ArgoCD detecta a mudanca e aplica no cluster automaticamente. Nao precisa de kubectl apply manual nem de pipelines complexas.

2. **Sincronizacao continua** - O ArgoCD monitora constantemente o cluster. Se alguem alterar algo manualmente (kubectl edit), o ArgoCD **reverte** para o que esta no Git. Isso garante que o cluster nunca fique fora do esperado.

3. **Rollback simples** - Basta reverter o commit no Git. O ArgoCD detecta a reversao e volta o cluster ao estado anterior.

4. **Multi-cluster** - Um unico ArgoCD pode gerenciar varios clusters Kubernetes. Ideal para ambientes com dev, staging e producao.

5. **Visualizacao do estado** - A UI do ArgoCD mostra uma arvore com todos os recursos (deployments, pods, services) e seu estado (saudavel, degradado, out-of-sync).

### Como o GitOps funciona?

```
Voce (dev)         Git           ArgoCD         Cluster Kubernetes
    |               |              |                  |
    |-- git push -->|              |                  |
    |               |-- (armazena) |                  |
    |               |              |-- detecta ->     |
    |               |              |-- kubectl apply->|
    |               |              |<-- estado atual -|
    |<-- Synced ----|              |                  |
```

---

## Componentes do ArgoCD

Quando o ArgoCD e instalado, ele cria varios pods no namespace `argocd`:

| Pod                                | Funcao                                           | Quem acessa?      |
|------------------------------------|--------------------------------------------------|-------------------|
| `argocd-server`                    | UI web, API REST, CLI gRPC                       | Voce (dev/ops)    |
| `argocd-repo-server`               | Clona repos, gera manifests (helm/kustomize)     | Interno           |
| `argocd-application-controller`    | Compara Git vs cluster, aplica diff              | Interno           |
| `argocd-redis`                     | Cache de estado (nao usado por aplicacoes)       | Interno           |
| `argocd-dex-server`                | Autenticacao SSO (OIDC, LDAP, SAML)              | Opcional          |

---

## Conceitos Fundamentais

### Application

Uma **Application** e um recurso do ArgoCD que diz:
- Qual repositorio Git monitorar (`source`)
- Qual caminho dentro do repositorio (`path`)
- Em qual namespace/cluster aplicar (`destination`)
- Como sincronizar (`sync policy`)

Exemplo:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-pedidos
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/meu/time/app-pedidos.git
    targetRevision: main
    path: k8s/overlays/prod
  destination:
    server: https://kubernetes.default.svc
    namespace: pedidos
  syncPolicy:
    automated:
      prune: true      # remove recursos que nao estao no Git
      selfHeal: true   # reverte mudancas manuais
```

### Project

Um **Project** agrupa Applications e define limites:
- Quais namespaces podem ser usados
- Quais repositorios sao permitidos
- Quem pode acessar (RBAC)

### Sync (Sincronizacao)

Estados possiveis de uma Application:

| Estado       | Significado                       |
|--------------|-----------------------------------|
| **Synced**   | Cluster identico ao Git           |
| **OutOfSync**| Cluster diferente do Git          |
| **Syncing**  | Aplicando mudancas no momento     |

### Sync Policy

| Opcao       | Efeito                                                              |
|-------------|---------------------------------------------------------------------|
| prune: true | Remove recursos que existem no cluster mas nao estao no Git         |
| selfHeal    | Reverte alteracoes manuais no cluster                               |
| allowEmpty  | Permite que a aplicacao fique sem recursos temporariamente          |

---

## Instalacao

Via Helm:

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd -f config/values.yaml -n argocd --create-namespace
```

### Verificar instalacao

```bash
kubectl get pods -n argocd                    # todos Running
kubectl get svc -n argocd                     # services criados
kubectl get ingress -n argocd                 # se configurado
```

---

## Acesso

### Via Ingress

Acesse: `https://argocd.dev.local`

Se estiver em lab local sem DNS:
```bash
# /etc/hosts
127.0.0.1 argocd.dev.local
```

### Via Port-Forward

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443
```
Acesse: `http://localhost:8080`

### Obter senha do admin

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Usuario: `admin`

---

## CLI (argocd)

### Instalacao

```bash
# macOS
brew install argocd

# Linux
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd
```

### Comandos essenciais

```bash
# Login (apos port-forward)
argocd login localhost:8080 --username admin --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Listar aplicacoes
argocd app list

# Ver detalhes
argocd app get app-pedidos

# Sincronizar
argocd app sync app-pedidos

# Sincronizar com prune (remove recursos que nao estao no Git)
argocd app sync app-pedidos --prune

# Ver logs do sync
argocd app logs app-pedidos

# Alterar senha
argocd account update-password
```

---

## Criando a Primeira Application

### Via UI

1. Acesse o ArgoCD
2. Clique em "+ New App"
3. Preencha:

   | Campo            | Exemplo                                           |
   |------------------|---------------------------------------------------|
   | Application Name | app-pedidos                                       |
   | Project          | default                                           |
   | Sync Policy      | Automatic (marque Prune e Self-Heal)              |
   | Repository URL   | https://github.com/meu/time/app-pedidos.git       |
   | Revision         | main                                              |
   | Path             | k8s/overlays/dev                                  |
   | Cluster URL      | https://kubernetes.default.svc                    |
   | Namespace        | pedidos                                           |

4. Clique em "Create" > "Sync" > "Synchronize"

### Via CLI

```bash
argocd app create app-pedidos \
  --project default \
  --repo https://github.com/meu/time/app-pedidos.git \
  --revision main \
  --path k8s/overlays/dev \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace pedidos \
  --sync-policy automated \
  --auto-prune \
  --self-heal
```

### Via YAML (declarativo)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-pedidos
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/meu/time/app-pedidos.git
    targetRevision: main
    path: k8s/overlays/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: pedidos
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Aplique: `kubectl apply -f app-pedidos.yaml`

---

## ApplicationSet (Multiplos ambientes)

O **ApplicationSet** gera multiplas Applications a partir de um template. Muito util para criar ambientes (dev, staging, prod) com a mesma configuracao.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: app-pedidos
  namespace: argocd
spec:
  generators:
    - list:
        elements:
          - environment: dev
            namespace: pedidos-dev
          - environment: staging
            namespace: pedidos-staging
          - environment: prod
            namespace: pedidos-prod
  template:
    metadata:
      name: 'app-pedidos-{{environment}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/meu/time/app-pedidos.git
        targetRevision: main
        path: 'k8s/overlays/{{environment}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{namespace}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
```

---

## Integracao com Observabilidade

### ServiceMonitor para Prometheus

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: argocd-metrics
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: argocd-metrics-server
  namespaceSelector:
    matchNames:
      - argocd
  endpoints:
    - port: metrics
      interval: 30s
```

### Alertas Uteis

```yaml
groups:
  - name: argocd
    rules:
      - alert: ArgoCDAppOutOfSync
        expr: argocd_app_info{sync_status!="Synced"} > 0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "App {{ $labels.name }} esta out-of-sync"

      - alert: ArgoCDAppDegraded
        expr: argocd_app_info{health_status="Degraded"} > 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "App {{ $labels.name }} esta degradada"
```

---

## Troubleshooting

### ArgoCD nao sincroniza

Possiveis causas:

1. **Problema de conexao com o repositorio**
   ```bash
   kubectl logs -n argocd deploy/argocd-repo-server
   ```

2. **SSH key ou token invalido** - Se o repo e privado, configure credenciais
   ```bash
   argocd repo add https://github.com/meu/time/app-pedidos.git --username user --token tok
   ```

3. **Path inexistente** - O caminho no repositorio nao existe
   ```bash
   git ls-tree --name-only main k8s/overlays/dev/
   ```

### rpc error: code = Unauthenticated

O token expirou. Faca login novamente:

```bash
argocd login localhost:8080 --username admin --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
```

### Ingress nao funciona

```bash
kubectl get pods -n ingress-nginx           # Ingress Controller rodando?
kubectl get ingress -n argocd               # Ingress criado?
nslookup argocd.dev.local                   # DNS aponta para IP correto?
```

---

## Boas Praticas

1. **Sempre use syncPolicy.automated com prune e selfHeal** - Senao o cluster pode ficar fora do estado esperado.

2. **Nunca altere o cluster manualmente** - O ArgoCD vai reverter e voce perde o trabalho.

3. **Separe ambientes em diretorios** - Use k8s/overlays/dev, k8s/overlays/prod com Kustomize ou Helm.

4. **Use Projects para isolar times** - Cada time no seu project, com acesso aos seus namespaces.

5. **Configure notificacoes** - ArgoCD pode notificar Slack, email, Discord.
   ```bash
   argocd notify slack --channel #deployments --token xoxb-...
   ```

6. **Mantenha o ArgoCD atualizado** - Versoes antigas tem bugs de seguranca.
   ```bash
   helm upgrade argocd argo/argo-cd --version 7.8.1 -n argocd -f config/values.yaml
   ```

---

## Referencias

- [Documentacao oficial do ArgoCD](https://argo-cd.readthedocs.io/)
- [Helm Chart do ArgoCD](https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd)
- [Exemplos de Application](https://github.com/argoproj/argocd-example-apps)
- [Metricas do ArgoCD](https://argo-cd.readthedocs.io/en/stable/operator-manual/metrics/)
- [Notificacoes](https://argocd-notifications.readthedocs.io/)
