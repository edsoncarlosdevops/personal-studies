# Loki — Guia de Domínio

> O que você precisa saber para configurar, otimizar e depurar o Loki como um expert.

## Sumário

- [Coleta e Agentes](#coleta-e-agentes)
- [Pipeline Stages](#pipeline-stages)
- [Storage](#storage)
- [LogQL Essencial](#logql-essencial)
- [Depuração](#depuração)
- [Performance](#performance)

---

## Coleta e Agentes

### Qual agente usar?

| Agente | Quando usar |
|--------|-------------|
| **Promtail** | Apenas Loki, descoberta nativa Kubernetes, mais simples |
| **Fluent Bit** | Stack de logging multi-destino (Loki + Elastic + S3) |
| **Grafana Alloy** | Stack Grafana completa (Loki, Tempo, Prometheus), pipeline visual |

### Promtail — Configuração Essencial

```yaml
scrape_configs:
  - job_name: kubernetes-pods
    kubernetes_sd_configs:
      - role: pod
    pipeline_stages:
      - cri: {}                          # parse CRI log format
      - regex:
          expression: '^(?P<level>\w+)\s+(?P<message>.*)$'
      - labels:
          level:
      - timestamp:
          source: time
          format: RFC3339Nano
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_label_app]
        target_label: app
      - source_labels: [__meta_kubernetes_namespace]
        target_label: namespace
      - source_labels: [__meta_kubernetes_pod_name]
        target_label: pod
      - action: keep
        regex: true
        source_labels: [__meta_kubernetes_pod_annotation_grafana_com_loki_scrape]
```

### Fluent Bit — Configuração Essencial

```yaml
[INPUT]
    Name              tail
    Path              /var/log/containers/*.log
    multiline.parser  cri

[FILTER]
    Name                kubernetes
    Match               *
    Kube_Tag_Prefix     kube.*

[OUTPUT]
    Name                loki
    Match               *
    Host                loki.monitoring.svc.cluster.local
    Port                3100
    Labels              {job="fluentbit"}
    Auto_Kubernetes_Labels on
```

---

## Pipeline Stages

O pipeline do Promtail processa cada linha de log em stages:

```yaml
pipeline_stages:
  # 1. Parse — extrair dados estruturados
  - regex:
      expression: '^(?P<timestamp>\S+)\s+(?P<level>\S+)\s+(?P<message>.*)$'

  # 2. JSON — se o log for JSON
  - json:
      expressions:
        level: level
        message: msg
        trace_id: trace_id

  # 3. logfmt — se o log for key=value
  - logfmt:
      mapping:
        level: level
        msg: msg

  # 4. Timestamp — extrair timestamp do log (não usar o do Promtail)
  - timestamp:
      source: timestamp
      format: RFC3339Nano

  # 5. Labels — criar labels a partir do log
  - labels:
      level:
      app:

  # 6. Drop — descartar linhas que não interessam
  - drop:
      expression: 'healthcheck|heartbeat'

  # 7. Multiline — juntar stack traces
  - multiline:
      firstline: '^\d{4}-\d{2}-\d{2}'
      max_lines: 100
      max_wait_time: 3s

  # 8. Static Labels — adicionar labels fixas
  - static_labels:
      source: kubernetes
```

---

## Storage

### TSDB Index (Loki 2.8+)

A partir do Loki 2.8, o **TSDB index** substituiu o boltdb-shipper.

| Característica | boltdb-shipper | TSDB |
|---------------|----------------|------|
| Performance | ✅ Bom | 🔥 Excelente |
| Consumo de memória | Alto | Baixo |
| Query em dados antigos | Lento | Rápido |
| Compaction | Manual | Automática |

### Configuração Essencial

```yaml
ingester:
  chunk_idle_period: 30m        # tempo antes de flush
  chunk_retain_period: 1m       # manter na memória após flush
  max_chunk_age: 2h             # chunk máximo de idade
  max_transfer_retries: 0       # desabilitar transferência (Loki 3+)

querier:
  query_ingesters_within: 3h    # consultar ingesters para dados recentes

query_frontend:
  align_queries_with_step: true
  cache_results: true

compactor:
  retention_enabled: true       # habilitar retenção
  retention_rules:
    - selector:
        match: '{namespace="monitoring"}'
      period: 30d               # manter 30 dias
    - selector:
        match: '{namespace!~".*"}'
      period: 7d                # outros só 7 dias
```

### Limitações Conhecidas

- `max_look_back_period`: Loki NÃO consulta dados anteriores a esse período
- `reject_old_samples`: descarta amostras com timestamp muito antigo
- `creation_grace_period`: janela de tolerância para timestamp futuro

```yaml
limits_config:
  max_look_back_period: 72h       # só consegue ver 72h pra trás
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  creation_grace_period: 10m
```

---

## LogQL Essencial

### Filtros

```logql
# Básico — contém string
{namespace="monitoring"} |= "error"

# Regex
{namespace="monitoring"} |~ "err(or|o)"

# Negativo
{namespace="monitoring"} != "debug"

# Múltiplos labels
{namespace="monitoring", pod=~"api-.*"}
```

### Parse

```logql
# JSON automático
{namespace="monitoring"} | json

# logfmt (key=value)
{namespace="monitoring"} | logfmt

# Regex
{namespace="monitoring"} | regex "^(?P<ip>\\S+)\\s+(?P<method>\\S+)\\s+(?P<path>\\S+)"

# Pattern (mais rápido que regex)
{namespace="monitoring"} | pattern "<ip> - - <_> \"<method> <path> <_>\" <status> <size>"
```

### Métricas a partir de Logs

```logql
# Taxa de erro por namespace
rate({namespace="monitoring"} |= "error" [5m])

# Total de erros nas últimas 24h
sum(count_over_time({namespace="monitoring"} |= "error" [24h]))

# Top 5 containers com mais erros
topk(5, sum by (container) (rate({namespace="monitoring"} |= "error" [5m])))

# Percentual de erro
sum(rate({namespace="monitoring"} |= "error" [5m])) / sum(rate({namespace="monitoring"}[5m])) * 100
```

### Labels vs Linhas

```logql
# Retorna séries (para gráficos)
rate({namespace="monitoring"} |= "error" [5m])

# Retorna linhas (para tabela/logs panel)
{namespace="monitoring"} |= "error"
```

---

## Depuração

### Endpoints Úteis

| Endpoint | O que mostra |
|----------|--------------|
| `/loki/api/v1/label` | Labels disponíveis |
| `/loki/api/v1/label/{name}/values` | Valores de uma label |
| `/loki/api/v1/series` | Séries que correspondem a um filtro |
| `/ready` | Health check |
| `/metrics` | Métricas do próprio Loki |

### Métricas do Próprio Loki

```promql
# Ingestão
rate(loki_ingester_chunks_flushed_total[5m])
rate(loki_ingester_lines_received_total[5m])

# Queries
histogram_quantile(0.99, rate(loki_request_duration_seconds_bucket{route=~".*query.*"}[5m]))

# Erros
rate(loki_request_duration_seconds_count{status_code=~"5.."}[5m])

# Memória do ingester
loki_ingester_memory_chunks
process_resident_memory_bytes{job="loki"}
```

### Debug com logcli

```bash
# Instalar
docker run --rm grafana/logcli --help

# Consultar logs
logcli query '{namespace="monitoring"}' --tail

# Descobrir labels
logcli labels

# Valores de uma label
logcli labels namespace

# Série específica
logcli series '{namespace="monitoring"}'
```

### Problemas Comuns

| Sintoma | Causa | Solução |
|---------|-------|---------|
| "Data not found" | `max_look_back_period` muito curto | Aumentar para 72h+ |
| Ingester OOM | `chunk_idle_period` muito longo | Reduzir para 30m |
| Query lenta | Muitas labels de alta cardinalidade | Revisar pipeline stages |
| Logs não aparecem | Label `namespace` não configurada | Verificar relabel_configs |
| `max_entries_limit_per_query` | Limite de resultados | Aumentar ou paginar |

---

## Performance

### Boas Práticas

```yaml
# ❌ Evite labels de alta cardinalidade
labels:
  request_id:   # NUNCA — cada request vira uma série
  ip:           # NUNCA — cada IP vira uma série
  user_id:      # NUNCA — cada usuário vira uma série

# ✅ Prefira filtros no LogQL (mais barato)
{namespace="monitoring"} |= "error"
# Em vez de criar label "level=error"

# Use structured metadata (Loki 3+)
- structured_metadata:
    target_label: trace_id
```

### Recomendações de Recurso

| Tamanho | Logs/dia | Ingester | Querier | Storage |
|---------|----------|----------|---------|---------|
| Pequeno | < 100GB | 2 CPU / 4GB | 1 CPU / 2GB | S3/OSS |
| Médio | 100GB-1TB | 4 CPU / 8GB | 2 CPU / 4GB | S3/OSS |
| Grande | 1TB+ | 8 CPU / 16GB | 4 CPU / 8GB | S3/OSS + caching |

---

## Desafios Práticos

### 🟢 Nível 1 — Iniciante

#### Desafio 1: Encontrar logs de erro de um serviço específico

**Contexto:** Você quer ver todos os logs de erro do serviço `api-pedidos` nos últimos 30 minutos.

**Ocorre quando:** Um usuário reportou erro, ou você viu um alerta de HTTP 500 e precisa investigar a causa raiz.

**Query LogQL:**
```logql
{namespace="monitoring", app="api-pedidos"} |= "error" |= "exception"
```

**Entendendo:** `{namespace, app}` filtra pelo serviço, `|= "error"` seleciona linhas com "error", `|= "exception"` também captura exceções em stack trace.

**Como depurar se não funcionar:**
```bash
# Descobrir labels disponíveis
curl -s 'http://localhost:3100/loki/api/v1/label'

# Ver se há logs para esse serviço
logcli query '{namespace="monitoring"}' --limit=1

# Se não houver resultados, verificar:
# 1. O agente (Promtail/FluentBit) está rodando?
# 2. As labels foram configuradas corretamente?
# 3. O Loki está recebendo dados? (curl /metrics | grep loki_ingester_lines_received)
```

---

#### Desafio 2: Taxa de erros por minuto

**Contexto:** Você quer um gráfico mostrando quantos erros estão ocorrendo por minuto para detectar picos.

**Ocorre quando:** Dashboard de monitoramento de aplicação, ou alerta de aumento súbito de erros.

**Query LogQL:**
```logql
sum(rate({namespace="monitoring"} |= "error" [1m]))
```

**Entendendo:** `rate(...[1m])` calcula a taxa de linhas por segundo (depois converte para "por minuto" no eixo Y). `sum()` agrega todos os streams.

**Para visualizar no Grafana:**
- Tipo de painel: **Time series**
- Unidade: **ops (operations per second)** ou **cpm (counts per minute)**
- Legenda: `{{namespace}}`

---

#### Desafio 3: Contar ocorrências de um termo específico

**Contexto:** Você quer saber quantas vezes uma determinada transação aparece nos logs (ex: "pedido_criado", "pagamento_aprovado").

**Ocorre quando:** Auditoria, debugging de fluxo completo, ou verificar se uma feature está sendo usada.

**Query LogQL:**
```logql
sum(count_over_time({namespace="monitoring"} |= "pedido_criado" [24h]))
```

**Entendendo:** `count_over_time(...[24h])` conta quantas linhas contendo "pedido_criado" ocorreram nas últimas 24h. Útil para métricas de negócio a partir de logs.

**Variação com agrupamento:**
```logql
sum by (app) (count_over_time({namespace="monitoring"} |= "pedido_criado" [24h]))
```

---

### 🟡 Nível 2 — Intermediário

#### Desafio 4: Parse de JSON em logs estruturados

**Contexto:** Seus logs estão em formato JSON e você quer extrair campos específicos como `trace_id`, `user_id`, `duration_ms` para filtrar e analisar.

**Ocorre quando:** Aplicações que já emitem logs estruturados (JSON), comum em Golang, Node.js, Python com structlog.

**Log de exemplo:**
```json
{"level": "error", "message": "timeout ao conectar", "service": "api-pedidos", "trace_id": "abc123", "duration_ms": 5000}
```

**Query LogQL:**
```logql
{namespace="monitoring"} | json | duration_ms > 1000
```

**Entendendo:** `| json` extrai automaticamente todos os campos do JSON. Depois você pode filtrar por qualquer campo como se fosse label. Não precisa configurar pipeline stages no Promtail para isso.

**Extraindo para labels (mais rápido para queries frequentes):**
```yaml
pipeline_stages:
  - json:
      expressions:
        level: level
        trace_id: trace_id
  - labels:
      level:
```

**Como depurar se o parse não funcionar:**
```bash
# Ver o log raw
logcli query '{namespace="monitoring"}' --limit=5

# Ver se o JSON é válido
echo '{"level":"error"}' | jq .

# Se o log não for JSON puro (ex: prefixo com timestamp), usar regex primeiro
```

---

#### Desafio 5: Identificar picos de latência (requests lentos)

**Contexto:** Os logs contêm `duration_ms` (tempo de resposta) e você quer encontrar os requests mais lentos.

**Ocorre quando:** Performance degradation, usuários reclamando de lentidão, ou planejamento de otimização.

**Query LogQL:**
```logql
{namespace="monitoring"} | json | duration_ms > 2000 | line_format "{{.duration_ms}}ms - {{.message}}"
```

**Entendendo:** `| json` extrai `duration_ms`, `duration_ms > 2000` filtra requests que levaram mais de 2s, `line_format` personaliza a exibição.

**No Grafana (tabela):**
```logql
{namespace="monitoring"} | json | duration_ms > 2000
```
Ordene por `duration_ms` descendente.

**Métrica a partir disso:**
```logql
# Percentual de requests lentos
sum(rate({namespace="monitoring"} | json | duration_ms > 2000 [5m]))
/
sum(rate({namespace="monitoring"} | json [5m])) * 100
```

---

#### Desafio 6: Monitorar log de erros por serviço em tempo real

**Contexto:** Você quer um painel que mostre a taxa de erros de cada serviço em tempo real, atualizado a cada 5 segundos.

**Ocorre quando:** War room (incidente em andamento), onde você precisa ver o erro subindo em tempo real.

**Query LogQL:**
```logql
topk(10, sum by (app) (rate({namespace="monitoring"} |= "error" [1m])))
```

**Configuração no Grafana:**
- Refresh: **5s** (não 30s)
- Time range: **Now-15m** (para foco no recente)
- Tipo: **Bar chart** (melhor para comparar serviços)

**Entendendo:** `topk(10, sum by(app)(...))` mostra os 10 apps com mais erro no momento. Útil para identificar rapidamente qual serviço está degradado.

**Alerta associado:**
```logql
# Se qualquer serviço tiver > 10 erros/min
max by (app) (rate({namespace="monitoring"} |= "error" [5m])) > 0.17  # ~10/min
```

---

### 🔴 Nível 3 — Avançado

#### Desafio 7: Pipeline stages complexos para logs não estruturados

**Contexto:** Seus logs são texto livre (ex: logs legados) e você precisa extrair campos como IP, método HTTP, status code e tempo de resposta.

**Ocorre quando:** Aplicações antigas, logs de terceiros, ou middleware que não emite JSON.

**Log de exemplo:**
```
192.168.1.1 - - [22/Jun/2026:14:00:00] "POST /api/pedidos HTTP/1.1" 200 123 "curl/7.0" 0.450
```

**Pipeline Promtail:**
```yaml
pipeline_stages:
  - regex:
      expression: '^(?P<ip>\S+)\s+\S+\s+\S+\s+\[(?P<timestamp>[^\]]+)\]\s+"(?P<method>\S+)\s+(?P<path>\S+)\s+\S+"\s+(?P<status>\d+)\s+(?P<size>\d+)\s+"(?P<user_agent>[^"]*)"\s+(?P<duration>\S+)$'
  - timestamp:
      source: timestamp
      format: "02/Jan/2006:15:04:05 -0700"
  - labels:
      status:
      method:
  - metrics:
      http_requests_total:
        type: Counter
        description: "Total de requests HTTP"
        prefix: loki_
        match: .*
        action: inc
      http_request_duration_seconds:
        type: Histogram
        description: "Duração dos requests"
        prefix: loki_
        match: .*
        buckets: [0.1, 0.5, 1, 2, 5]
        source: duration
```

**Entendendo:** O `regex` extrai 9 campos do log. `timestamp` converte a data. `labels` cria labels para filtrar no Grafana. `metrics` gera métricas a partir dos logs (Loki → Prometheus via metrics stage).

---

#### Desafio 8: Correlacionar logs com traces (TraceID nos logs)

**Contexto:** Seus logs contêm `trace_id` e você quer clicar em um log e abrir o trace completo no Tempo.

**Ocorre quando:** Debugging de ponta a ponta — você vê um erro no log e quer ver o trace completo (spans) para entender o que aconteceu.

**Configuração no datasource Loki:**

No arquivo de datasource do Grafana:
```yaml
datasources:
  - name: Loki
    type: loki
    jsonData:
      derivedFields:
        - name: trace_id
          matcherRegex: 'trace_id=(\w+)'
          url: '$${__value.raw}'
          datasourceUid: P214B5B846CF3925F
```

**Uso:** Quando você abre um log no Grafana e ele contém `trace_id=abc123`, o campo vira um link clicável que abre o trace no Tempo.

**Query LogQL:**
```logql
{namespace="monitoring"} |= "error" | json | trace_id != ""
```

**Como depurar se não funcionar:**
```bash
# Verificar se o trace_id está no log
logcli query '{namespace="monitoring"}' --limit=1 | grep -o 'trace_id=[^ ]*'

# Verificar se o datasource Tempo está configurado com o UID correto
curl -s http://localhost:3000/api/datasources | jq '.[] | select(.type=="tempo") | .uid'
```

---

#### Desafio 9: Logs → Métricas → Alerta (cadeia completa)

**Contexto:** Você quer gerar uma métrica a partir de logs (ex: taxa de erro de um serviço), criar um alerta no Prometheus, e notificar no Slack.

**Ocorre quando:** Você não consegue instrumentar a aplicação, mas tem os logs. Extrair métricas dos logs é a única alternativa.

**Pipeline no Promtail (metrics stage):**
```yaml
pipeline_stages:
  - regex:
      expression: '.*(?P<level>ERROR|WARN|INFO).*'
  - metrics:
      log_entries_total:
        type: Counter
        description: "Total de logs por nível"
        prefix: loki_
        match: .*
        action: inc
      log_entries_by_level:
        type: Counter
        description: "Logs por nível"
        prefix: loki_
        match: .*
        action: inc
        labels:
          level:
```

**No Prometheus:**
```promql
# Taxa de erros
rate(loki_log_entries_by_level_total{level="ERROR"}[5m])

# % de erro
rate(loki_log_entries_by_level_total{level="ERROR"}[5m])
/
rate(loki_log_entries_total[5m]) * 100
```

**Alerta no Prometheus:**
```yaml
groups:
  - name: log_based_alerts
    rules:
      - alert: HighLogErrorRate
        expr: |
          rate(loki_log_entries_by_level_total{level="ERROR"}[5m])
          /
          rate(loki_log_entries_total[5m]) * 100 > 10
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: 'Taxa de erro nos logs > 10%'
```

**Fluxo completo:**
```
Log → Promtail → Loki (armazena) + Prometheus (métrica loki_log_*) → Alerta → Slack
```

---

#### Desafio 10: Criar métricas de negócio a partir de logs

**Contexto:** Sua aplicação não expõe métricas de negócio (pedidos criados, pagamentos processados), mas esses eventos estão nos logs.

**Ocorre quando:** Times de produto querem métricas de negócio, mas a aplicação não está instrumentada.

**Log de exemplo:**
```json
{"event": "order_created", "order_id": "123", "amount": 150.00, "customer": "joao"}
```

**Pipeline:**
```yaml
pipeline_stages:
  - json:
      expressions:
        event: event
        amount: amount
  - metrics:
      business_events_total:
        type: Counter
        description: "Eventos de negócio"
        prefix: biz_
        match: .*
        action: inc
        labels:
          event:
      business_revenue_total:
        type: Counter
        description: "Receita total"
        prefix: biz_
        match: .*
        action: inc
        labels:
          event:
        value: amount  # incrementa pelo valor do campo amount
```

**No Prometheus:**
```promql
# Pedidos criados por minuto
rate(biz_business_events_total{event="order_created"}[5m])

# Receita total no mês
sum(increase(biz_business_revenue_total{event="order_created"}[30d]))
```

**Entendendo:** O metrics stage do Promtail pode criar counters e histograms a partir de campos do log. O campo `value` permite incrementar pelo valor de um campo (ex: amount), não apenas contar linhas.
