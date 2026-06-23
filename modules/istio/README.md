# Istio

## O que e Istio?

Istio e um service mesh (malha de servicos). Ele adiciona um proxy (Envoy) ao lado de cada pod e gerencia TODO o trafego de rede entre os servicos.

### Para que serve?

Istio adiciona 4 capacidades principais ao seu cluster:

1. **Seguranca (mTLS)** — Toda comunicacao entre pods e criptografada automaticamente. Nenhum servico consegue bisbilhotar o trafego de outro.

2. **Observabilidade** — Cada requisicao entre servicos gera metricas (taxa, latencia, erros), tracing distribuido e logs de acesso. Tudo sem modificar o codigo da aplicacao.

3. **Controle de trafego** — Canary (10% do trafego para nova versao), blue-green, circuit breaker (para de enviar se esta dando erro), retries (tenta de novo se falhar), timeouts.

4. **Resiliencia** — Se um servico esta lento ou falhando, o Istio pode: parar de enviar trafego, tentar novamente com backoff, ou redirecionar para um servico alternativo.

### Como o Istio funciona?

```
Antes do Istio:
Pod A ──── HTTP ──── Pod B

Depois do Istio:
Pod A ──── Envoy A ──── mTLS ──── Envoy B ──── Pod B
              │                            │
         Proxy intercepta             Proxy recebe,
         todo trafego de saida        aplica politicas
```

O Envoy e um proxy que fica dentro do pod (ao lado da aplicacao). Ele intercepta todo o trafego de entrada e saida. A aplicacao NÃO sabe que o Envoy existe.

### Diferenca entre Istio e Ingress Controller

Esta e a confusao mais comum. A diferenca e simples:

| Caracteristica | Nginx Ingress | Istio |
|---------------|---------------|-------|
| Onde atua | Na borda (fora → dentro) | Dentro do cluster (pod → pod) |
| O que faz | Roteia trafego externo para servicos | Gerencia trafego entre servicos |
| mTLS | Nao | Sim |
| Canary | Via annotation | Nativo (VirtualService) |
| Tracing | Nao | Nativo (Envoy envia spans) |
| Circuit breaker | Nao | Sim |

**Resumo**: Nginx Ingress = porteiro do predio. Istio = corredores entre os apartamentos.

Na pratica, voce pode usar os DOIS: Nginx Ingress para entrada e Istio para comunicacao interna.

---

## Componentes do Istio

```
                    ┌──────────────────────┐
                    │       istiod          │
                    │   (Control Plane)     │
                    │  Gerencia proxies,    │
                    │  distribui configs    │
                    └──────┬───────────────┘
                           │
          ┌────────────────┼──────────────────┐
          │                │                   │
   ┌──────▼──────┐  ┌─────▼──────┐   ┌────────▼───────┐
   │ Envoy (Pod A)│  │ Envoy (Pod B)│   │ Ingress Gateway│
   │ Sidecar proxy│  │ Sidecar proxy│   │ (proxy de borda)│
   └─────────────┘  └──────────────┘   └────────────────┘
```

### 1. istiod (Control Plane)

istiod e o cerebro do Istio. Ele:

- Escuta por mudancas nos recursos do Istio (VirtualService, DestinationRule, etc.)
- Gera configuracao de proxy para cada Envoy
- Distribui certificados mTLS para cada pod
- Envia as configuracoes atualizadas para os Envoys via xDS (protocolo de descoberta)

istiod NAO fica no caminho dos dados. Ele so configura os proxies. Se istiod cair, os proxies continuam funcionando com a ultima configuracao recebida.

### 2. Envoy (Data Plane)

O Envoy e um proxy de alto desempenho escrito em C++. Ele roda como sidecar em cada pod.

**O que o Envoy faz em cada requisicao:**

```
1. Recebe requisicao do cliente
2. Verifica se o cliente tem certificado mTLS valido
3. Aplica politicas de autorizacao (AuthorizationPolicy)
4. Verifica se o servico destino esta saudavel (health check)
5. Aplica regras de trafego (canary, timeout, retry)
6. Gera metricas (istio_requests_total, latencia)
7. Gera spans para tracing distribuido
8. Encaminha para o servico destino
```

**Tudo isso acontece em microssegundos.** O overhead do Envoy e de 1-5ms por requisicao.

### 3. Ingress Gateway

O Ingress Gateway e um Envoy especial que fica na borda do cluster. Ele substitui o Nginx Ingress Controller.

```
Internet → Istio Ingress Gateway → Servicos internos
```

Diferenca para o Nginx Ingress:

```
Nginx:     Internet → Nginx → Servico (sem mTLS)
Istio GW:  Internet → Istio GW → Envoy sidecar → Servico (com mTLS ate o ultimo hop)
```

---

## Conceitos Fundamentais

### VirtualService

Define COMO o trafego chega a um servico. Ex: 90% para versao stable, 10% para versao canary.

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: api-pedidos
spec:
  hosts:
    - api-pedidos
  http:
    - match:
        - headers:
            x-canary:
              exact: "true"
      route:
        - destination:
            host: api-pedidos
            subset: canary
    - route:
        - destination:
            host: api-pedidos
            subset: stable
          weight: 90
        - destination:
            host: api-pedidos
            subset: canary
          weight: 10
```

### DestinationRule

Define as politicas para um servico destino: versoes (subsets), circuit breaker, mTLS, conexoes maximas.

```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: api-pedidos
spec:
  host: api-pedidos
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100       # maximo de conexoes simultaneas
      http:
        http1MaxPendingRequests: 10
        maxRequestsPerConnection: 10
    loadBalancer:
      simple: LEAST_CONN          # distribui para quem tem menos conexoes
    outlierDetection:
      consecutive5xxErrors: 5      # se 5 erros consecutivos, remove do pool
      interval: 30s                # verifica a cada 30s
      baseEjectionTime: 60s        # fica fora por 60s
  subsets:
    - name: stable
      labels:
        version: stable
    - name: canary
      labels:
        version: canary
```

### AuthorizationPolicy

Define quem pode falar com quem. Ex: apenas api-pedidos pode falar com api-pagamentos.

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: api-pagamentos-policy
spec:
  selector:
    matchLabels:
      app: api-pagamentos
  rules:
    - from:
        - source:
            principals:
              - "cluster.local/ns/default/sa/api-pedidos"
      to:
        - operation:
            methods: ["POST", "GET"]
```

### PeerAuthentication

Define o nivel de mTLS entre os pods.

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: default
spec:
  mtls:
    mode: PERMISSIVE  # STRICT (apenas TLS), PERMISSIVE (TLS + texto plano), DISABLE
```

---

## Fluxo Completo (Passo a Passo)

### Cenário: Canary Deployment com Istio

```
1. Voce tem a versao stable do api-pedidos rodando
2. Voce faz deploy da versao canary (com label version: canary)
3. Voce cria um DestinationRule com subsets: stable e canary
4. Voce cria um VirtualService: 90% stable, 10% canary
5. Istio configura os Envoys de TODOS os pods para fazer esse roteamento
6. 10% das requisicoes vao para o canary, 90% para o stable
7. Se o canary esta OK, voce muda para 50/50
8. Se tudo OK, 100% para canary (que vira a nova stable)
```

**Sem Istio**: voce precisaria de um load balancer externo, configurar DNS, e gerenciar manualmente.

**Com Istio**: 3 arquivos YAML (VirtualService + DestinationRule + Deployment) e pronto.

---

## Instalacao

```bash
# Adicionar repositorios Helm do Istio
helm repo add istio https://istio-release.storage.googleapis.com/charts

# Instalar os CRDs do Istio (Custom Resource Definitions)
helm install istio-base istio/base -n istio-system --create-namespace

# Instalar o Control Plane (istiod)
helm install istiod istio/istiod -f config/values.yaml -n istio-system

# Instalar o Ingress Gateway
helm install istio-ingressgateway istio/gateway -f config/values.yaml -n istio-system
```

### Verificar instalacao

```bash
# Ver pods do Istio
kubectl get pods -n istio-system
# Deve mostrar: istiod-xxx (1/1 Running) e istio-ingressgateway-xxx (1/1 Running)

# Verificar sidecar injection
kubectl get mutatingwebhookconfiguration istio-sidecar-injector
```

### Habilitar Istio em um namespace

```bash
kubectl label namespace default istio-injection=enabled
```

Apos isso, todo pod NOVO nesse namespace tera o sidecar Envoy automaticamente.

**IMPORTANTE**: So afeta pods criados DEPOIS do label. Pods existentes precisam ser recriados:

```bash
kubectl rollout restart deployment -n default
```

### Remover Istio de um namespace

```bash
kubectl label namespace default istio-injection-
```

---

## Funcionalidades Principais (Comandos e Exemplos)

### 1. Canary Deployment

```yaml
# 1. DestinationRule: define as versoes
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: api-pedidos
spec:
  host: api-pedidos
  subsets:
    - name: stable
      labels:
        version: stable
    - name: canary
      labels:
        version: canary
---
# 2. VirtualService: 90% stable, 10% canary
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: api-pedidos
spec:
  hosts:
    - api-pedidos
  http:
    - route:
        - destination:
            host: api-pedidos
            subset: stable
          weight: 90
        - destination:
            host: api-pedidos
            subset: canary
          weight: 10
```

### 2. Circuit Breaker

```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: api-pagamentos-circuit-breaker
spec:
  host: api-pagamentos
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 10       # so 10 conexoes simultaneas
      http:
        http1MaxPendingRequests: 5   # so 5 requisicoes na fila
    outlierDetection:
      consecutive5xxErrors: 3    # se 3 erros consecutivos
      interval: 30s               # verifica a cada 30s
      baseEjectionTime: 30s       # remove do pool por 30s
      maxEjectionPercent: 50      # remove no max 50% dos pods
```

### 3. Timeout e Retry

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: api-pagamentos-timeout-retry
spec:
  hosts:
    - api-pagamentos
  http:
    - timeout: 3s                    # se demorar mais de 3s, cancela
      retries:
        attempts: 3                  # tenta 3 vezes
        perTryTimeout: 2s            # cada tentativa tem 2s de timeout
        retryOn: connect-failure,refused-stream,503
      route:
        - destination:
            host: api-pagamentos
```

### 4. Fault Injection (testar resiliencia)

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: api-pagamentos-fault
spec:
  hosts:
    - api-pagamentos
  http:
    - fault:
        delay:
          percentage:
            value: 50               # 50% das requisicoes
          fixedDelay: 5s             # atraso de 5 segundos
        abort:
          percentage:
            value: 10               # 10% das requisicoes
          httpStatus: 500            # retornam HTTP 500
      route:
        - destination:
            host: api-pagamentos
```

**ATENCAO**: Fault injection e para TESTE. Nunca use em producao.

### 5. Mirroring (copiar trafego para debug)

Envia copia do trafego para um servico de debug sem afetar os usuarios reais.

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: api-pedidos-mirror
spec:
  hosts:
    - api-pedidos
  http:
    - mirror:
        host: api-pedidos-debug          # copia para o debug
      mirrorPercentage:
        value: 100.0                      # 100% das requisicoes
      route:
        - destination:
            host: api-pedidos             # original continua normal
```

---

## Valores de Configuracao (values.yaml)

O arquivo `config/values.yaml` contem todas as opcoes comentadas. Abaixo, as principais:

### `meshConfig.enableAutoMtls`

Habilita mTLS automatico entre todos os servicos.

```
meshConfig:
  enableAutoMtls: true
```

- `true` (recomendado): todo trafego entre pods e criptografado automaticamente.
- `false`: trafego em texto plano.

Mesmo com `true`, durante a migracao, o Istio aceita trafego sem TLS se o servico destino nao tiver sidecar (modo PERMISSIVE).

### `meshConfig.accessLogFormat`

Formato dos logs de acesso do Envoy.

```
meshConfig:
  accessLogFile: /dev/stdout
  accessLogFormat: |
    {"start_time": "%START_TIME%", "method": "%REQ(:METHOD)%", ...}
```

Cada requisicao gera uma linha de log JSON no stdout do sidecar. Isso pode ser coletado pelo Loki.

### `meshConfig.enableTracing`

Habilita tracing distribuido.

```
meshConfig:
  enableTracing: true
  defaultConfig:
    tracing:
      zipkin:
        address: tempo.monitoring.svc.cluster.local:4317
```

Quando ativado, cada requisicao entre servicos gera spans que sao enviados para o Tempo. Voce pode ver a waterfall completa no Grafana.

### `gateways.ingress`

Configuracao do Ingress Gateway (proxy de borda).

```
gateways:
  ingress:
    enabled: true
    replicas: 2
    service:
      type: LoadBalancer
```

- `type: LoadBalancer`: cria um Load Balancer na nuvem (AWS NLB, GCP GLB).
- `type: NodePort`: expoe em portas altas dos nodes (lab).
- `type: ClusterIP`: interno (precisa de outro ingress na frente).

---

## Troubleshooting

### Sidecar nao foi injetado no pod

```bash
# Verificar se o namespace tem o label
kubectl get namespace default -o yaml | grep istio-injection
# Deve mostrar: istio-injection: enabled

# Se o label existe, o pod pode ter sido criado antes
kubectl rollout restart deployment meu-deploy -n default

# Verificar logs do webhook
kubectl logs -n istio-system deploy/istiod | grep inject
```

### "upstream connect error or disconnect/reset before headers"

O Envoy nao conseguiu se conectar ao servico destino.

```bash
# Causas comuns:
# 1. O servico destino nao tem sidecar
# 2. mTLS STRICT + servico sem sidecar
# 3. O servico destino esta caindo (CrashLoopBackOff)

# Verificar se o servico destino tem sidecar
kubectl get pods -l app=meu-servico
# Deve mostrar 2/2 containers (app + istio-proxy)

# Se estiver em PERMISSIVE, aceita conexao sem sidecar
# Se estiver em STRICT, nao aceita
```

### "RBAC: access denied"

O AuthorizationPolicy esta bloqueando a requisicao.

```bash
# Verificar AuthorizationPolicy
kubectl get authorizationpolicy -A

# Verificar logs do Envoy
kubectl logs -n default deploy/meu-servico -c istio-proxy | grep denied
```

### Service graph vazio no Grafana

O tracing nao esta configurado ou o Tempo nao esta recebendo spans.

```bash
# Verificar tracing config
kubectl get configmap -n istio-system istio -o yaml | grep tracing

# Verificar se o Tempo recebe spans
curl -s http://localhost:3100/metrics | grep tempo_ingester_spans_received
```

### Envoy consumindo muita memoria

O Envoy pode consumir mais memoria que o esperado em clusters grandes.

```bash
# Verificar uso do Envoy
kubectl top pods -n default

# Aumentar limits no values.yaml
proxy:
  resources:
    limits:
      memory: 512Mi  # aumentar de 256Mi para 512Mi
```

---

## Performance e Overhead

### Quanto o Istio adiciona de latencia?

- **Sem Istio**: latencia pura da rede (microssegundos)
- **Com Istio (sem mTLS)**: +1-2ms por requisicao
- **Com Istio (com mTLS)**: +2-5ms por requisicao

Para 99% das aplicacoes, esse overhead e irrelevante. Para aplicacoes de alta frequencia (trading, jogos), pode ser significativo.

### Quanto de recurso o Envoy consome?

- **CPU**: 0.1-0.5 core por pod (depende do trafego)
- **Memoria**: 50-200MB por pod (depende do numero de endpoints)

Para um cluster com 100 pods, sao 5-20GB de memoria extra para os sidecars.

---

## Boas Praticas

1. **Comece com PERMISSIVE** — Deixe o Istio aceitar trafego com e sem TLS durante a migracao.
2. **Habilite sidecar injection por namespace** — Nao individualmente por pod.
3. **Nao use Istio se nao precisa** — Se voce tem 5 pods e 1 servico, Istio e overkill.
4. **Monitore o Envoy** — Ele e um processo extra, pode consumir recursos.
5. **Teste fault injection em staging** — Nunca em producao.
6. **Prefira Nginx Ingress para entrada e Istio para trafego interno** — Nao precisa substituir o Ingress se o Istio vai ser usado apenas internamente.

---

## Referencias

- [Documentacao oficial do Istio](https://istio.io/latest/docs/)
- [Istio Helm Chart](https://istio.io/latest/docs/setup/install/helm/)
- [Istio VirtualService](https://istio.io/latest/docs/reference/config/networking/virtual-service/)
- [Istio DestinationRule](https://istio.io/latest/docs/reference/config/networking/destination-rule/)
- [Istio Security](https://istio.io/latest/docs/concepts/security/)
- [Envoy Proxy](https://www.envoyproxy.io/)
