# Thanos

## O que e Thanos?

Thanos e um conjunto de componentes que estendem o Prometheus, adicionando armazenamento de longa duracao (meses/anos) e consulta global (consultar dados de varios clusters ao mesmo tempo).

### Para que serve?

Thanos resolve 3 problemas do Prometheus puro:

#### Problema 1: Retencao limitada

O Prometheus armazena dados no disco local do pod. Se voce configurar `retention: 30d`, depois de 30 dias os dados sao deletados. Com Thanos, voce pode manter dados por meses ou anos em um bucket S3.

```
Prometheus puro:           [30 dias] ✂️ depois apaga
Com Thanos:     [Prometheus (30 dias)] + [S3 (12 meses)] + [Downsample (anos)]
```

#### Problema 2: Perda de dados se o pod morre

O Prometheus e stateless — os dados estao no disco do pod. Se o pod morre, os dados se vao junto. O Thanos Sidecar envia copias para o S3 continuamente, entao mesmo que o pod morra, os dados historicos estao seguros.

#### Problema 3: Nao da para consultar multiplos clusters

Cada cluster tem seu proprio Prometheus. Para ver dados de todos os clusters no mesmo grafico, voce precisava configurar um federate manualmente. O Thanos Query junta tudo automaticamente.

```
Cluster A: Prometheus A ─── Thanos Sidecar A ─┐
                                               ├── Thanos Query ← Grafana
Cluster B: Prometheus B ─── Thanos Sidecar B ─┘
```

---

## Diferenca entre Thanos e Prometheus

| Caracteristica | Prometheus Sozinho | Prometheus + Thanos |
|---------------|-------------------|---------------------|
| Retencao | 15-30 dias (disco local) | Meses/anos (object storage) |
| Durabilidade | Perde se pod morre | Dados seguros no S3 |
| Consulta multi-cluster | Nao (federate manual) | Sim (Thanos Query) |
| Downsampling | Nao | Sim (1h, 5m, raw) |
| Compressao | Nao | Sim (compactor) |
| Complexidade | Baixa | Alta |

---

## Componentes do Thanos

```
                         ┌──────────────────┐
                         │   Object Storage  │
                         │    (S3 / MinIO)   │
                         └────────┬─────────┘
                                  │
            ┌─────────────────────┼──────────────────────┐
            │                     │                      │
    ┌───────▼───────┐     ┌──────▼──────┐      ┌────────▼────────┐
    │  Store        │     │  Compactor  │      │  Receive        │
    │  (le do S3)   │     │ (compacta)  │      │ (ingestao remota)│
    └───────┬───────┘     └─────────────┘      └────────┬────────┘
            │                                           │
            └─────────────────┬─────────────────────────┘
                              │
                      ┌───────▼───────┐
                      │  Query        │ ←── Grafana consulta aqui
                      │  (ponto unico)│
                      └───────┬───────┘
                              │
            ┌─────────────────┼──────────────────┐
            │                 │                   │
    ┌───────▼───────┐ ┌──────▼──────┐    ┌───────▼───────┐
    │  Sidecar A    │ │  Sidecar B  │    │  Sidecar C    │
    │  (Prometheus) │ │  (Prometheus)│    │  (Prometheus) │
    └───────────────┘ └─────────────┘    └───────────────┘
```

### 1. Sidecar

Roda ao lado de cada Prometheus. Faz 2 coisas:

- **Upload para S3**: Periodicamente, envia os blocks de dados do Prometheus para o object storage.
- **Proxy de query**: O Thanos Query consulta o Sidecar (gRPC porta 10901) para obter dados RECENTES que ainda nao foram para o S3.

```
Prometheus ── Sidecar ── S3 (dados antigos)
                 │
                 └── Thanos Query (dados recentes, na memoria do Prometheus)
```

### 2. Store

Serve dados HISTORICOS do S3. Quando o Query recebe uma consulta, ele pergunta ao Store pelos dados antigos.

```
Grafana → Query: "me de CPU dos ultimos 90 dias" → Store: "pega do S3"
                                                  → Sidecar: "pega do Prometheus (dados recentes)"
```

### 3. Compactor

Faz 3 coisas com os blocks no S3:

- **Compactacao**: Junta blocks pequenos em blocks maiores (mais eficiente).
- **Downsampling**: Cria versoes com menos resolucao dos dados:
  - Raw: dados originais (alta resolucao, 30 dias)
  - 5m: agregado a cada 5 minutos (media resolucao, 90 dias)
  - 1h: agregado a cada 1 hora (baixa resolucao, 1 ano)
- **Deducacao**: Se 2 Prometheus coletaram a mesma metrica, o Compactor remove a duplicata.

**IMPORTANTE**: So deve ter 1 Compactor por cluster Thanos. Se tiver 2, eles competem pelos blocks e podem corromper os dados.

### 4. Query

E o ponto unico de consulta. O Grafana se conecta ao Query em vez de se conectar ao Prometheus.

```
Antes (sem Thanos):
Grafana → Prometheus A (dados do cluster A)

Depois (com Thanos):
Grafana → Thanos Query → Store (dados historicos do S3)
                       → Sidecar A (dados recentes do cluster A)
                       → Sidecar B (dados recentes do cluster B)
```

**Para o Grafana, a experiencia e identica.** Ele so ve um datasource Prometheus comum. Quem gerencia a consulta distribuida e o Query.

### 5. Receive (opcional)

Alternativa ao Sidecar. Em vez de o Prometheus enviar dados para o S3 via Sidecar, o Receive recebe dados via Remote Write (push).

Use Receive quando:
- Voce usa Remote Write no Prometheus (em vez de Sidecar)
- Voce quer um ponto centralizado de ingestao
- Nao quer modificar a configuracao do Prometheus

---

## Instalacao

```bash
# Adicionar repositorio
helm repo add bitnami https://charts.bitnami.com/bitnami

# Instalar Thanos (Store + Compactor + Query)
helm install thanos bitnami/thanos -f config/values.yaml -n thanos --create-namespace
```

### Pre-requisitos

Antes de instalar o Thanos, voce PRECISA de:

1. **Object Storage** (S3, MinIO, GCS, Azure Blob) — bucket para armazenar os dados historicos.
2. **Prometheus com Sidecar** — o Prometheus precisa estar configurado para enviar dados para o Thanos.
3. **Grafana apontando para o Query** — o datasource do Grafana precisa mudar para o Thanos Query.

Sem esses 3 itens, o Thanos nao faz nada util.

### Configurar Prometheus para usar Sidecar

No values.yaml do kube-prometheus-stack:

```yaml
prometheus:
  thanos:
    create: true        # cria o servico que o Sidecar precisa
    service:
      enabled: true     # expoe a porta 10901 gRPC
```

Isso faz com que o Prometheus seja descoberto automaticamente pelo Thanos Query via DNS.

### Configurar o Object Storage

No `config/values.yaml` do Thanos, configure o bucket S3 (ou MinIO local):

```yaml
objstoreConfig:
  type: s3
  config:
    bucket: thanos-data
    endpoint: s3.us-east-1.amazonaws.com
    access_key: ${AWS_ACCESS_KEY_ID}
    secret_key: ${AWS_SECRET_ACCESS_KEY}
```

Para usar MinIO local (lab):

```yaml
objstoreConfig:
  type: s3
  config:
    bucket: thanos-data
    endpoint: minio.monitoring.svc.cluster.local:9000
    insecure: true  # MinIO nao usa HTTPS
    access_key: minioadmin
    secret_key: minioadmin
```

### Configurar Grafana

No datasource do Grafana, mude a URL do Prometheus para o Thanos Query:

```yaml
datasources:
  - name: Prometheus
    type: prometheus
    url: http://thanos-query.thanos.svc.cluster.local:9090
    # Em vez de: http://prometheus-server:80
```

Pronto. O Grafana continua funcionando exatamente como antes, mas agora consulta dados historicos.

---

## Valores de Configuracao (values.yaml)

O arquivo `config/values.yaml` contem todas as opcoes comentadas. Abaixo, as principais:

### `objstoreConfig`

Configuracao do object storage.

```
objstoreConfig:
  type: s3
  config:
    bucket: thanos-data
    endpoint: s3.us-east-1.amazonaws.com
```

- `type`: `s3`, `gcs`, `azure`, `cos` (IBM), `oss` (Alibaba).
- `bucket`: nome do bucket.
- `endpoint`: URL do S3. Para MinIO, use o endereco do servico.
- `insecure`: `true` para MinIO (sem TLS), `false` para S3/GCS.

### `store.enabled`

Habilita o componente Store.

```
store:
  enabled: true
```

Sem o Store, o Query nao consegue ler dados historicos do S3.

### `compactor.enabled`

Habilita o componente Compactor.

```
compactor:
  enabled: true
  retentionResolutionRaw: 30d
  retentionResolution5m: 90d
  retentionResolution1h: 365d
```

- `retentionResolutionRaw`: quanto tempo manter dados brutos (alta resolucao).
- `retentionResolution5m`: quanto tempo manter downsampled de 5 minutos.
- `retentionResolution1h`: quanto tempo manter downsampled de 1 hora.

### `query.enabled`

Habilita o componente Query.

```
query:
  enabled: true
  replicas: 2
  dnsDiscovery:
    storeNamespace: thanos
    storeService: thanos-store
    sidecarsNamespace: monitoring
    sidecarsService: prometheus-thanos-discovery
```

- `dnsDiscovery`: o Query descobre automaticamente os Stores e Sidecars via DNS.
- `replicas`: 2 ou mais para alta disponibilidade.

---

## Fluxo Completo (Passo a Passo)

### Cenário: Voce quer consultar CPU dos ultimos 90 dias

```
1. Voce abre o Grafana e faz uma query de CPU dos ultimos 90 dias
2. Grafana envia a query para o Thanos Query (porta 9090)
3. Query descobre que:
   - Dados de 0-30 dias atras: estao no Sidecar (Prometheus local)
   - Dados de 30-90 dias atras: estao no Store (S3)
4. Query consulta ambos ao mesmo tempo
5. Query junta os resultados (merge) e retorna para o Grafana
6. Grafana mostra o grafico com 90 dias de dados
```

### O que o Compactor fez antes (em background)

```
1. Sidecar enviou blocks do Prometheus para o S3 a cada 2h
2. Compactor baixou blocks pequenos, juntou em blocks maiores
3. Compactor criou downsampled:
   - 5m: media de cada 5 minutos
   - 1h: media de cada 1 hora
4. Para consultar 90 dias, o Query usa downsampled 5m (mais rapido)
5. Para consultar 1 ano, o Query usa downsampled 1h (ainda mais rapido)
```

---

## Troubleshooting

### Thanos Query nao encontra dados recentes (Sidecar)

```bash
# Verificar se o Sidecar esta rodando junto com o Prometheus
kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus
# Deve mostrar 2/2 containers (prometheus + thanos-sidecar)

# Verificar se a descoberta DNS funciona
kubectl run -it --rm dns-test --image=busybox -- nslookup prometheus-thanos-discovery.monitoring
```

### Thanos Store nao inicia

Causa: configuracao do S3 esta errada ou bucket nao existe.

```bash
# Verificar logs
kubectl logs -n thanos deploy/thanos-store

# Testar acesso ao S3 manualmente
kubectl exec -n thanos deploy/thanos-store -- sh -c 'wget -q -O- http://minio:9000'
```

### "no store matched for this query"

O Query nao encontrou nenhum Store ou Sidecar que possa responder a consulta.

```bash
# Verificar stores conhecidos pelo Query
kubectl exec -n thanos deploy/thanos-query -- wget -q -O- http://localhost:9090/
# Nao ha um endpoint padrao, mas os logs do Query mostram as stores
kubectl logs -n thanos deploy/thanos-query | grep "store"
```

### Compactor com erro "block already exists"

Dois Compactors estao competindo pelos mesmos blocks.

```bash
# Verificar se ha mais de 1 compactor
kubectl get pods -n thanos -l app.thanos.com/component=compactor
# Deve mostrar apenas 1 pod
```

---

## Custo e Performance

### Quanto custa armazenar dados historicos?

Depende do volume de metricas e da compressao do Thanos.

Estimativa:
- 1000 series (metricas) x 1 ano x compressao ~ 5-10 GB no S3
- Custo S3: ~$0.023/GB/mes = ~$0.23/mes

Comparacao: manter no Prometheus local exigiria 10x mais disco (sem compressao).

### Performance de consulta

Consultar 1 ano de dados e mais lento que consultar 30 dias. Mas o downsampling ajuda:
- Dados raw: milissegundos para 30 dias
- Downsampled 5m: segundos para 90 dias
- Downsampled 1h: segundos para 1 ano

---

## Boas Praticas

1. **Nao instale Thanos sem necessidade** — Se 30 dias de retencao sao suficientes, nao complique.
2. **Configure downsampling correto** — Raw 30d, 5m 90d, 1h 1 ano.
3. **Monitore o Compactor** — Se ele parar, os blocks nunca serao compactados e o S3 enche de blocks pequenos.
4. **Use um unico Compactor** — Mais de 1 corrompe os dados.
5. **Nao use Receive e Sidecar juntos** — Escolha um dos dois.

---

## Referencias

- [Documentacao oficial do Thanos](https://thanos.io/)
- [Thanos Design Doc](https://thanos.io/tip/thanos/design.md/)
- [Bitnami Thanos Helm Chart](https://github.com/bitnami/charts/tree/main/bitnami/thanos)
- [Comparacao: Thanos vs Mimir vs VictoriaMetrics](https://thanos.io/tip/comparison.md/)
