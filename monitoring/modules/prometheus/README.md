# Prometheus — Guia de Domínio

> O que você precisa saber para configurar, otimizar e depurar o Prometheus como um expert.

## Sumário

- [Coleta e Descoberta](#coleta-e-descoberta)
- [Storage e Performance](#storage-e-performance)
- [Alerting e Recording Rules](#alerting-e-recording-rules)
- [PromQL Essencial](#promql-essencial)
- [Depuração](#depuração)
- [Cardinalidade](#cardinalidade)
- [Desafios Práticos](#desafios-práticos)

---

## Coleta e Descoberta

### ServiceMonitor vs PodMonitor vs Probe

| Tipo | Quando usar |
|------|-------------|
| **ServiceMonitor** | Serviço com `spec.selector` + porta nomeada (recomendado) |
| **PodMonitor** | Quando não há Service (ex: cAdvisor, node-exporter via DaemonSet) |
| **Probe** | Monitoramento externo (HTTP, TCP, ICMP) |

### relabel_configs — os 5 que você precisa saber

```yaml
relabel_configs:
  # 1. Dropar métricas que não interessam
  - source_labels: [__name__]
    regex: 'etcd_(.*)'
    action: drop

  # 2. Renomear label
  - source_labels: [__meta_kubernetes_pod_label_app]
    target_label: app
    action: replace

  # 3. Criar label a partir de metadados
  - source_labels: [__meta_kubernetes_namespace]
    target_label: namespace
    action: replace

  # 4. Manter apenas targets com label específica
  - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
    regex: 'true'
    action: keep

  # 5. Mapear porta correta
  - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
    regex: '([^:]+)(?::\d+)?;(\d+)'
    replacement: '$1:$2'
    target_label: __address__
    action: replace
```

### honor_labels

```yaml
# Quando o exportador já envia labels que você quer preservar
honor_labels: true   # não sobrescreve labels do target
honor_labels: false  # renomeia para exported_*
```

### scrape_interval e scrape_timeout

```yaml
# Configure por job, não global
scrape_configs:
  - job_name: 'cadvisor'
    scrape_interval: 15s   # padrão 60s é muito espaçado
    scrape_timeout: 10s    # sempre menor que scrape_interval
```

---

## Storage e Performance

### TSDB Internals

```
WAL (Write-Ahead Log) → Head (in-memory) → Blocks (on-disk)
```

- **WAL**: dados recentes (2h), seguro contra crash
- **Head**: dados em memória, consultas rápidas
- **Blocks**: compactados em disco, intervalos de 2h
- **Compaction**: junta blocks menores em maiores (reduz IO)

### Configuração Essencial

```yaml
storage:
  tsdb:
    retention:
      time: 30d        # quanto tempo manter
      size: 50GB       # limite de disco (opcional)
    wal_compression: true  # reduz IO de escrita
```

### Query Optimization

```promql
# ❌ Ruim — varre tudo
rate(container_cpu_usage_seconds_total[5m])

# ✅ Bom — filtra antes
rate(container_cpu_usage_seconds_total{namespace="monitoring"}[5m])

# ❌ Ruim — cardinalidade explode
count({__name__=~".*"}) by (instance, job, namespace, pod, container)

# ✅ Bom — específico
count(kube_pod_info) by (namespace)
```

### Quando usar rate vs increase

| Função | Retorna | Uso |
|--------|---------|-----|
| `rate(metric[5m])` | Taxa por segundo | CPU, requests/s, throughput |
| `increase(metric[5m])` | Valor total no período | Restarts, errors absolutos |
| `irate(metric[5m])` | Taxa instantânea | Picos rápidos (últimos 2 pontos) |

---

## Alerting e Recording Rules

### Estrutura de Regras

```yaml
groups:
  - name: observabilidade
    interval: 30s  # avalia a cada 30s (padrão 60s)
    rules:
      - record: namespace:cpu_usage:rate5m
        expr: |
          sum(rate(container_cpu_usage_seconds_total{namespace!=""}[5m])) by (namespace)

      - alert: HighCPUUsage
        expr: |
          namespace:cpu_usage:rate5m > 0.8
        for: 10m          # só dispara se sustentar por 10 min
        labels:
          severity: warning
        annotations:
          summary: '{{ $labels.namespace }} com CPU alta ({{ $value | humanizePercentage }})'
```

### Evitando Falso Positivo

```promql
# ❌ Dispara em pico de 1 minuto
rate(metric[1m]) > 0.9

# ✅ Só dispara se médio sustentado
avg_over_time(rate(metric[5m])[15m:1m]) > 0.9
```

---

## PromQL Essencial

### 4 Funções que Você TEM que Saber

```promql
rate(metric[5m])                           # taxa por segundo
increase(metric[5m])                       # valor total no período
avg_over_time(metric[5m])                  # média móvel
quantile_over_time(0.99, metric[5m])       # latência p99
```

### Join (Operação Binária)

```promql
# Multiplicar CPU usage pelo custo do node
rate(container_cpu_usage_seconds_total[5m]) * on(instance) group_left() node_cpu_hourly_cost

# Dividir uso por request
container_memory_working_set_bytes / on(container, pod) group_left() kube_pod_container_resource_requests{resource="memory"}
```

### Top k

```promql
# Top 5 namespaces por CPU
topk(5, sum(rate(container_cpu_usage_seconds_total{namespace!=""}[5m])) by (namespace))

# Bottom 5 (menos uso)
bottomk(5, sum(rate(container_cpu_usage_seconds_total{namespace!=""}[5m])) by (namespace))
```

---

## Depuração

### Endpoints Úteis

| Endpoint | O que mostra |
|----------|--------------|
| `/api/v1/status/tsdb` | Estatísticas do TSDB, séries por label |
| `/api/v1/targets` | Health, scrape duration, último erro |
| `/api/v1/rules` | Regras de alerta e recording |
| `/api/v1/alerts` | Alertas ativos |
| `/metrics` | Métricas do próprio Prometheus |

### Métricas do Próprio Prometheus

```promql
# Cardinalidade — quantas séries existem
prometheus_tsdb_head_series

# Scrapes com erro
rate(prometheus_target_scrapes_exceeded_sample_limit_total[5m])

# Queries lentas (>1s)
histogram_quantile(0.99, rate(prometheus_engine_query_duration_seconds_bucket[5m]))

# WAL replay time (no startup)
prometheus_tsdb_wal_replay_duration_seconds

# Uso de disco
prometheus_tsdb_storage_blocks_bytes
```

### Debug de Scrape

```bash
# Verificar se um target está sendo scapeado
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health=="down")'

# Ver amostras de uma métrica
curl -s 'http://localhost:9090/api/v1/query?query=up{job="prometheus"}'

# Valores disponíveis para uma label
curl -s 'http://localhost:9090/api/v1/label/namespace/values'
```

---

## Cardinalidade

### O Maior Problema do Prometheus

**Sintoma**: Prometheus lento, OOM, queries demoram, disco enche rápido.

**Diagnóstico**:

```promql
# Quantas séries no total
prometheus_tsdb_head_series

# Séries por job (top 5)
topk(5, count by (job) ({__name__=~".+"}))

# Labels que mais explodem
count by (__name__) ({__name__=~"container_(.*)"})
```

**Causas Comuns**:

| Causa | Exemplo | Solução |
|-------|---------|---------|
| Label com valor único por pod | `pod_ip`, `instance_id` | `metric_relabel_configs` para dropar |
| Request/path como label | `path="/api/users/123"` | Dropar ou sanitizar |
| Timestamp no label | `date="2026-06-22T14:00:00Z"` | Dropar — use tempo da série |
| Container efêmero | Jobs que criam pods únicos | Usar `__meta_kubernetes_pod_controller_kind=JobMonitor` |

**Prevenção**:

```yaml
metric_relabel_configs:
  - source_labels: [pod_ip]
    action: drop
  - source_labels: [container_id]
    action: drop
  - source_labels: [__name__]
    regex: 'etcd_(.*)'
    action: drop
```

---



---

## SLI, SLO e SLA — A Base da Observabilidade

Esses 3 conceitos sao fundamentais para monitoramento. Sem eles, voce apenas "olha graficos" sem saber o que e aceitavel ou nao.

### SLI (Service Level Indicator) — A metrica

SLI e a metrica BRUTA que mede algum aspecto do servico. E o dado puro.

| Aspecto | SLI (metrica) |
|---------|---------------|
| Disponibilidade | `avg(up)` = 0.98 (98%) |
| Latencia | `p95(request_duration)` = 200ms |
| Erro | `rate(http_5xx) / rate(http_total)` = 0.5% |
| Throughput | `rate(requests_total)` = 1000 req/s |

**SLI nao e "bom" ou "ruim"** — e apenas um numero. Voce precisa de um SLO para julgar.

### SLO (Service Level Objective) — A meta

SLO e a META que voce define para um SLI. E o que voce considera "dentro do aceitavel".

```
SLI: latencia p95 = 200ms
SLO: latencia p95 < 500ms em 95% do tempo (rolling 30 dias)

Interpretacao: em 95% do tempo dos ultimos 30 dias, a latencia
p95 ficou abaixo de 500ms. Se ficou acima, o SLO foi violado.
```

**Diferenca critica entre metricas**: SLO usa `for` ou janela de tempo. Nao adianta ter 1 minuto de latencia alta — o SLO mede se isso e sustentado.

```
# Exemplo de SLO no Prometheus:
# Queremos que a memoria NAO ultrapasse 90% do request
# por mais de 5 minutos consecutivos
expr: sum(container_memory_working_set_bytes) / sum(kube_pod_container_resource_requests{resource="memory"}) > 0.90
for: 5m
```

**Por que 90% e nao 85%?** Porque se o SLO dispara toda hora, voce para de prestar atencao. O threshold precisa ser alto o suficiente para so disparar quando realmente estiver perto do problema.

O SLO responde: "Esse servico esta saudavel OU precisa de atencao?"

### SLA (Service Level Agreement) — O contrato

SLA e o compromisso FORMAL com o cliente (ou com outro time). Geralmente tem consequencias financeiras.

```
SLI:  latencia p95
SLO:  latencia p95 < 1s em 99.9% do tempo (meta interna)
SLA:  latencia p95 < 2s em 99.5% do tempo (contrato com cliente)

Se violar o SLA: multa, credito, ou penalidade contratual.
Se violar o SLO: alerta, correcao, prevencao.
```

**Importante**: SLA quase sempre e MENOR (mais tolerante) que o SLO. Voce define SLOs mais rigorosos internamente para garantir que o SLA nunca seja violado.

### Resumo pratico

```
SLI = "quanto estamos errando?" (0.5% de erro)
SLO = "quanto podemos errar?" (max 1% de erro)
SLA = "quanto prometemos ao cliente?" (max 2% de erro, com multa se passar)

Seu SLO deve ser MAIS rigoroso que o SLA.
Se o SLO disparar, voce tem tempo de corrigir antes de violar o SLA.
```

### Como usar no dia a dia

1. **Defina SLIs para cada aspecto do servico**: disponibilidade, latencia, erro, throughput (RED metrics).
2. **Crie SLOs realistas**: com base no que voce ja observa, nao no que deseja.
3. **Ajuste os SLOs com o tempo**: se dispara muito, o threshold esta baixo ou os requests estao mal configurados.
4. **Nao crie SLO para tudo**: foque nos indicadores que realmente impactam o usuario final.
5. **SLAs sao contratuais**: envolva o time de produto e juridico para definir.


## Desafios Práticos

### 🟢 Nível 1 — Iniciante

#### Desafio 1: Descobrir qual namespace mais consome CPU

**Contexto:** Você precisa identificar quais equipes estão usando mais CPU no cluster para planejar capacidade ou cobrar custos internos (chargeback/showback).

**Ocorre quando:** Time de infra precisa reportar consumo por namespace, ou quando o cluster está próximo do limite e você precisa saber quem mais consome.

**Query:**
```promql
topk(10, sum(rate(container_cpu_usage_seconds_total{namespace!=""}[5m])) by (namespace))
```

**Entendendo:** `rate(...[5m])` calcula a média de CPU por segundo nos últimos 5 minutos, `sum by(namespace)` agrupa por namespace, `topk(10)` pega os 10 maiores.

**Como depurar se não funcionar:**
```bash
# Ver se a métrica existe
curl -s 'http://localhost:9090/api/v1/query?query=container_cpu_usage_seconds_total' | jq '.data.result | length'

# Ver namespaces disponíveis
curl -s 'http://localhost:9090/api/v1/label/namespace/values'
```

---

#### Desafio 2: Encontrar pod com mais restart

**Contexto:** Um pod está reiniciando constantemente e você precisa identificar qual é para investigar a causa (OOM, liveness probe, crash).

**Ocorre quando:** Pods em CrashLoopBackOff, ou você percebe downtime intermitente em um serviço.

**Query:**
```promql
topk(10, increase(kube_pod_container_status_restarts_total[24h]))
```

**Entendendo:** `increase(...[24h])` calcula quantos restart ocorreram nas últimas 24h, `topk(10)` lista os 10 com mais restart. Normalmente pods devem ter 0 ou 1 restart. Acima de 5 indica problema grave.

**Como depurar:**
```bash
# Ver restart de um pod específico
curl -s 'http://localhost:9090/api/v1/query?query=kube_pod_container_status_restarts_total{namespace="monitoring"}' | jq '.data.result[] | {pod: .metric.pod, restarts: .value[1]}'

# Causas comuns:
# - OOM (Out of Memory): aumentar limits
# - Liveness probe falhando: verificar endpoint
# - Aplicação crashando: ver logs no Loki
```

---

#### Desafio 3: Calcular % de memória usada vs request

**Contexto:** Você quer saber se os pods estão perto de estourar o limite de memória para planejar ajustes de resource requests/limits.

**Ocorre quando:** Planejamento de capacidade, ou antes de um deploy crítico para garantir que há folga.

**Query:**
```promql
sum(container_memory_working_set_bytes{namespace="monitoring"}) by (pod)
/
sum(kube_pod_container_resource_requests{namespace="monitoring", resource="memory"}) by (pod) * 100
```

**Entendendo:** Divide o uso real (`working_set_bytes`) pelo request configurado. >80% indica que precisa aumentar o request. >100% significa que está usando swap ou sendo throttled (se CPU).

**Interpretação:**
| % | Significado | Ação |
|---|-------------|------|
| <50% | Super provisionado | Reduzir request |
| 50-80% | Saudável | Manter |
| 80-100% | Próximo do limite | Aumentar request |
| >100% | Estourando | Aumentar request IMEDIATAMENTE |

---

### 🟡 Nível 2 — Intermediário

#### Desafio 4: Alerta "namespace X está sem deploy há 7 dias"

**Contexto:** Você quer saber se algum namespace está "abandonado" — tem pods rodando mas ninguém fez deploy recentemente. Pode indicar ambiente esquecido ou esteira quebrada.

**Ocorre quando:** Times mudam de projeto e esquecem de desativar ambientes, ou a pipeline de deploy quebrou silenciosamente.

**Query:**
```promql
time() - max(kube_deployment_created) by (namespace) > 604800
```

**Entendendo:** `kube_deployment_created` é o timestamp Unix de quando o deployment foi criado. `time() - ... > 604800` (7 dias em segundos) significa que nenhum deployment novo foi criado naquele namespace há mais de 7 dias.

**Como depurar:**
```bash
# Ver deployments e quando foram criados
curl -s 'http://localhost:9090/api/v1/query?query=kube_deployment_created' | jq '.data.result[] | {namespace: .metric.namespace, deployment: .metric.deployment, created: .value[1]}' | head -10

# Se a métrica não existir, verificar se kube-state-metrics está ativo
curl -s 'http://localhost:9090/api/v1/query?query=kube_deployment_created'
```

**Nota:** Essa query pega a criação inicial. Para detectar "último deploy" (nova imagem), use `kube_deployment_status_observed_generation` ou labels de imagem.

---

#### Desafio 5: Dashboard com dropdown de namespace (Template Variable)

**Contexto:** Você quer um dashboard onde o usuário seleciona um namespace e todos os painéis filtram automaticamente.

**Ocorre quando:** Qualquer dashboard que precise ser reutilizável para vários times ambientes.

**Configuração no Grafana:**
```
Tipo: Query
Name: namespace
Query: label_values(kube_namespace_created, namespace)
Multi-value: true
Include All option: true
```

**Nos painéis:**
```promql
# Antes (fixo):
rate(container_cpu_usage_seconds_total{namespace="monitoring"}[5m])

# Depois (dinâmico):
rate(container_cpu_usage_seconds_total{namespace=~"$namespace"}[5m])
```

**Entendendo:** A variável `$namespace` é substituída pelo valor selecionado no dropdown. `=~` permite regex, então pode selecionar múltiplos.

**Como depurar se não funcionar:**
```bash
# Ver se a query da variável retorna resultados
curl -s 'http://localhost:9090/api/v1/query?query=label_values(kube_namespace_created,%20namespace)' | jq '.data.result'

# Se vazio, usar fonte alternativa:
label_values(kube_pod_info, namespace)
```

---

#### Desafio 6: Detectar vazamento de memória

**Contexto:** Um pod está consumindo cada vez mais memória com o tempo, sem nunca liberar. Isso causa OOM eventualmente.

**Ocorre quando:** Aplicações com memory leak, conexões não fechadas, caches sem limite.

**Query:**
```promql
# Variação do uso nas últimas 6h
deriv(container_memory_working_set_bytes{namespace="monitoring"}[6h])
```

**Entendendo:** `deriv()` calcula a inclinação da curva de uso. Valor positivo = memória crescendo (vazamento), valor próximo de zero = estável.

**Alertando:**
```promql
# Alerta se a memória crescer continuamente por 2h
deriv(container_memory_working_set_bytes{namespace="monitoring"}[2h]) > 0.1
```

---

### 🔴 Nível 3 — Avançado

#### Desafio 7: Calcular custo estimado por deployment

**Contexto:** Você quer saber quanto cada deployment custa em termos de infraestrutura (CPU + RAM), mesmo sem OpenCost.

**Ocorre quando:** Times de finanças pedem relatório de custo, ou você quer comparar eficiência entre serviços.

**Query:**
```promql
# Custo estimado por deployment ($/h)
sum by (deployment, namespace) (
  rate(container_cpu_usage_seconds_total{container!=""}[5m]) * 0.04   # $0.04/core-hora
  +
  container_memory_working_set_bytes{container!=""} / 1024 / 1024 / 1024 * 0.005  # $0.005/GB-hora
)
```

**Entendendo:** Cada núcleo de CPU custa ~$0.04/hora e cada GB de RAM ~$0.005/hora (valores aproximados para nuvem). Multiplique pelo uso real. Para custo mensal, multiplique por 730 (horas no mês).

**Como depurar:**
```bash
# Verificar se as métricas existem
curl -s 'http://localhost:9090/api/v1/query?query=container_cpu_usage_seconds_total{container!=""}' | jq '.data.result | length'

# Ajustar valores de custo conforme sua nuvem (AWS, Azure, GCP)
```

**Variação com preços reais:**
```promql
# AWS us-east-1 (instância t3.medium como referência)
# CPU: $0.0416/hora, RAM: $0.0056/GB-hora
sum by (namespace) (
  rate(container_cpu_usage_seconds_total{container!=""}[5m]) * 0.0416
  +
  container_memory_working_set_bytes{container!=""} / 1024 / 1024 / 1024 * 0.0056
) * 730  # custo mensal estimado
```

---

#### Desafio 8: Service graph — traces → métricas → alertas

**Contexto:** Você quer monitorar a comunicação entre serviços (ex: api-pedidos → api-pagamentos). Quando um serviço está lento ou com erro, o service graph mostra.

**Ocorre quando:** Arquitetura de microsserviços com múltiplas chamadas entre serviços.

**Pré-requisitos:**
- Tempo com metrics_generator ativado
- Prometheus recebendo métricas do Tempo (`traces_service_graph_*`)
- No mínimo 2 serviços se comunicando

**Query:**
```promql
# Taxa de erro entre serviços
rate(traces_service_graph_request_failed_total{cluster="monitoring"}[5m])
/
rate(traces_service_graph_request_total{cluster="monitoring"}[5m]) * 100

# Latência p99
histogram_quantile(0.99, rate(traces_service_graph_request_duration_seconds_bucket[5m]))
```

**Alerta:**
```promql
# Se erro > 5% entre api-pedidos e api-pagamentos
rate(traces_service_graph_request_failed_total{cluster="monitoring"}[5m])
/
rate(traces_service_graph_request_total{cluster="monitoring"}[5m]) * 100 > 5
```

**Como depurar se não funcionar:**
```bash
# Verificar se metrics_generator está ativo
curl -s 'http://localhost:9090/api/v1/query?query=traces_service_graph_request_total' | jq '.data.result'

# Se vazio:
# 1. Verificar se Tempo tem metrics_generator configurado
# 2. Verificar se remote_write aponta para o Prometheus correto
# 3. Verificar se há spans de 2 serviços diferentes
```

---

#### Desafio 9: SLO com burn rate alerting

**Contexto:** Você tem um SLO de 99.9% de disponibilidade e quer ser alertado antes de violá-lo. Burn rate alerting detecta quando o erro está acelerando.

**Ocorre quando:** Equipe de plataforma define SLOs formais para serviços críticos.

**Conceito:** Burn rate = taxa na qual o orçamento de erro está sendo consumido. Se o burn rate > 1, você vai violar o SLO antes do período.

**Query (SLO 99.9%, janela de 1h):**
```promql
# Erro total na última hora
sum(rate(http_requests_total{status=~"5.."}[1h]))
/
sum(rate(http_requests_total[1h]))
*
# Se > 0.1% de erro, está queimando orçamento
100 > 0.1
```

**Burn rate em 3 janelas (multi-window):**
```promql
# Alerta se erro > 0.1% nos últimos 5m E > 0.05% nos últimos 30m
# Isso evita falso positivo (pico curto)
sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) * 100 > 0.1
and
sum(rate(http_requests_total{status=~"5.."}[30m])) / sum(rate(http_requests_total[30m])) * 100 > 0.05
```

**Entendendo:** A condição `and` exige que ambas as métricas sejam verdadeiras. Isso significa que o erro está elevado tanto na janela curta (5m) quanto na longa (30m), indicando um problema real, não um pico isolado.

---

#### Desafio 10: Predição de saturação de disco

**Contexto:** Você quer saber quando o disco de um node vai encher para planejar expansão antes do incidente.

**Ocorre quando:** Nodes com disco local, ou volumes com crescimento constante (logs, dados de banco).

**Query:**
```promql
# Prever disponibilidade em 7 dias
predict_linear(node_filesystem_avail_bytes{mountpoint="/", fstype!=""}[7d], 7*24*3600) < 0
```

**Entendendo:** `predict_linear()` usa regressão linear nos últimos 7 dias de dados para projetar o valor em 7 dias (7*24*3600 segundos). Se a projeção for < 0, o disco vai encher.

**Alerta em 2 estágios:**
```promql
# Warning: disco vai encher em 7 dias
predict_linear(node_filesystem_avail_bytes{mountpoint="/", fstype!=""}[7d], 7*24*3600) < 10*1024*1024*1024

# Critical: disco vai encher em 48h
predict_linear(node_filesystem_avail_bytes{mountpoint="/", fstype!=""}[7d], 48*3600) < 0
```

**Como depurar:**
```bash
# Ver espaço atual
curl -s 'http://localhost:9090/api/v1/query?query=node_filesystem_avail_bytes{mountpoint="/"}' | jq '.data.result[].value[1]'
# Converter: divida por 1024^3 para GB
```
