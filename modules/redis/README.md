# Redis

## O que e Redis?

Redis e um armazenamento de estrutura de dados em memoria, do tipo chave-valor. Ele e extremamente rapido porque os dados ficam na RAM, nao em disco.

### Para que serve?

Redis e usado principalmente para:

1. **Cache** — Armazenar respostas de consultas lentas (banco de dados, APIs externas). A proxima vez que o dado for requisitado, o Redis responde instantaneamente sem precisar consultar a origem novamente.

2. **Sessoes de usuario** — Manter dados de sessao (carrinho de compras, preferencias, autenticacao). Como e rapido, a experiencia do usuario e fluida.

3. **Filas** — Usando listas (LPUSH/BRPOP) para processamento assincrono. Exemplo: uma API recebe um pedido, coloca na fila do Redis, um worker processa em background.

4. **Rate limiting** — Controlar quantas requisicoes um usuario pode fazer por minuto. Redis e atomico, entao funciona mesmo com milhares de requisicoes simultaneas.

5. **Publicacao/Assinatura (Pub/Sub)** — Notificar eventos em tempo real. Exemplo: quando um pedido e criado, publica no Redis e todos os subscribers recebem a notificacao.

### Como o Redis funciona?

```
Aplicacao → Comando (SET "usuario:123" "joao") → Redis (memoria RAM)
                                                      |
                                           Resposta instantanea ("OK")
                                                      |
Aplicacao → Comando (GET "usuario:123") → Redis (memoria RAM) → "joao"
```

Diferente de um banco relacional (PostgreSQL, MySQL), o Redis nao precisa de schemas nem indices. Voce simplesmente define uma chave (ex: `usuario:123`) e um valor (ex: `{"nome": "Joao", "email": "joao@email.com"}`).

---

## Topologia (Arquitetura)

O Redis pode ser instalado de 3 formas, dependendo da necessidade:

### 1. Standalone (mais simples)

Um unico pod Redis, sem replicacao.

```
[App] → [Redis] (unico ponto de falha)
```

- **Quando usar**: Cache de curta duracao, laboratorio, desenvolvimento.
- **Pro**: Simples, nao precisa configurar replicacao.
- **Contra**: Se o pod cair, perde todos os dados (mesmo com persistencia, ha perda do que nao foi persistido).

### 2. Replication (leitura distribuida)

Um master (escrita) + N replicas (leitura).

```
[App] → Escrita: [Master]
         Leitura: [Replica 1], [Replica 2]
```

- **Quando usar**: Aplicacao com muita leitura (mais leitura que escrita).
- **Pro**: Distribui a carga de leitura entre varias replicas.
- **Contra**: Se o master cai, nao ha escrita ate recuperar.

### 3. Sentinel (alta disponibilidade)

Master + Replicas + Sentinels (monitoram e fazem failover).

```
[App] → [Sentinel] monitora [Master]
                          se Master cai → [Sentinel] promove Replica a Master
                          [App] descobre novo Master via Sentinel
```

- **Quando usar**: Dados que nao podem ser perdidos e precisam de alta disponibilidade.
- **Pro**: Failover automatico, aplicacao nao precisa saber quem e o master.
- **Contra**: Mais complexo, requer 3+ pods.

### Qual escolher?

| Situacao | Arquitetura |
|----------|-------------|
| "So um cache rapido, pode perder" | Standalone |
| "Muita leitura, escrita moderada" | Replication |
| "Dado critico, nao pode perder" | Sentinel (3+ pods) |
| "Lab/teste, aprendendo" | Standalone |

---

## Instalacao

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install redis bitnami/redis -f config/values.yaml -n redis --create-namespace
```

### Verificar se instalou corretamente

```bash
# Ver pods
kubectl get pods -n redis

# Ver status do Redis
kubectl exec -n redis deploy/redis-master -- redis-cli ping
# Resposta esperada: PONG
```

---

## Valores de Configuracao (values.yaml)

O arquivo `config/values.yaml` contem todas as opcoes comentadas. Abaixo, uma explicacao detalhada das principais:

### `architecture`

Define como o Redis sera instalado.

```
architecture: standalone
```

Opcoes:
- `standalone`: Um pod, sem replicacao.
- `replication`: Master + replicas.
- `sentinel`: Master + replicas + sentinels (HA).

### `auth.enabled`

Habilita autenticacao por senha.

```
auth:
  enabled: true
```

Se `false`, qualquer pessoa que acessar a porta 6379 consegue ler e escrever dados. Em producao, sempre deixe `true`.

A senha e gerada automaticamente e armazenada em um Secret. Para obter:

```bash
kubectl get secret redis -n redis -o jsonpath="{.data.redis-password}" | base64 -d
```

### `persistence`

Redis e em memoria, mas pode persistir dados em disco. Existem duas estrategias:

**RDB (Redis Database)**: Snapshots periodicos do banco inteiro.

```
save 3600 1    # snapshot a cada 3600s se ao menos 1 chave mudou
save 300 100   # snapshot a cada 300s se ao menos 100 chaves mudaram
```

- **Pro**: Arquivo compacto, restauracao rapida.
- **Contra**: Se o Redis cai entre snapshots, perde os dados do periodo.

**AOF (Append Only File)**: Log de cada operacao de escrita.

```
appendonly yes
appendfsync everysec  # escreve no disco a cada 1 segundo
```

- **Pro**: Mais seguro, perde no maximo 1 segundo de dados.
- **Contra**: Arquivo maior que RDB, restauracao mais lenta.

### `metrics.serviceMonitor`

Habilita a coleta de metricas pelo Prometheus Operator.

```
metrics:
  enabled: true
  serviceMonitor:
    enabled: true
    namespace: monitoring
```

Quando ativado, o redis-exporter (que roda como sidecar no pod do Redis) expoe metricas como `redis_up`, `redis_memory_used_bytes`, `redis_keyspace_hits_total`. O Prometheus Operator descobre automaticamente e comeca a coletar.

---

## Comandos Essenciais do Redis (para testar)

Apos fazer port-forward:

```bash
kubectl port-forward -n redis svc/redis-master 6379:6379
```

Conecte usando redis-cli (se nao tiver instalado, use `brew install redis` ou `docker run --rm -it redis redis-cli`):

```bash
# Conectar com senha
redis-cli -h localhost -a $(kubectl get secret redis -n redis -o jsonpath="{.data.redis-password}" | base64 -d)

# Dentro do redis-cli:

# SET: armazena um valor
SET usuario:1 "Joao"

# GET: recupera um valor
GET usuario:1
# Resposta: "Joao"

# EXPIRE: define tempo de expiracao (em segundos)
EXPIRE usuario:1 60
# O Redis apagara essa chave apos 60 segundos

# TTL: tempo restante de vida (em segundos)
TTL usuario:1
# Resposta: 45 (se ja passaram 15s)

# INCR: incrementa valor numerico (atomicamente)
INCR contador:acessos
# Resposta: 1
INCR contador:acessos
# Resposta: 2

# EXISTS: verifica se chave existe
EXISTS usuario:1
# Resposta: 1 (sim) ou 0 (nao)

# DEL: deleta uma chave
DEL usuario:1

# KEYS: lista chaves (CUIDADO: nao use em producao com muitas chaves)
KEYS *
```

### Estrutura de dados

Diferente de um banco relacional com tabelas e colunas, no Redis voce escolhe o tipo de dado mais adequado:

| Tipo | Exemplo | Uso |
|------|---------|-----|
| String | `SET usuario:1 "Joao"` | Dados simples, contadores |
| List | `LPUSH fila:pedidos "123"` | Filas (LPUSH/BRPOP) |
| Set | `SADD tags:post:1 "redis" "cache"` | Unicos, sem repeticoes |
| Hash | `HSET usuario:1 nome "Joao" idade 30` | Objetos com multiplos campos |
| Sorted Set | `ZADD ranking 100 "joao" 90 "maria"` | Rankings, ordenacao por pontuacao |

---

## Integracao com Aplicacao (exemplo Python)

```python
import redis
import os

# Conectar ao Redis
r = redis.Redis(
    host="redis-master.redis.svc.cluster.local",
    port=6379,
    password=os.environ.get("REDIS_PASSWORD"),
    decode_responses=True  # retorna strings, nao bytes
)

# Armazenar no cache (expira em 5 minutos)
r.setex("consulta:pedidos:2026-06-01", 300, resultado_json)

# Recuperar do cache
dados = r.get("consulta:pedidos:2026-06-01")
if dados:
    return dados  # cache hit
else:
    dados = consultar_banco()  # cache miss
    r.setex("consulta:pedidos:2026-06-01", 300, dados)
    return dados
```

---

## Troubleshooting

### "Redis is configured to save RDB snapshots, but it's currently unable to persist to disk"

O Redis nao tem permissao de escrita no volume.

```
kubectl logs -n redis deploy/redis-master
# Verificar se o PVC esta montado corretamente
kubectl describe pvc redis-data-redis-master-0 -n redis
```

### "MISCONF Redis is configured to save RDB snapshots"

Disco cheio ou sem permissao.

```
# Ver espaco em disco
kubectl exec -n redis deploy/redis-master -- df -h
```

### "Could not connect to Redis at 127.0.0.1:6379: Connection refused"

O Redis nao esta rodando ou nao esta ouvindo na porta.

```
kubectl get pods -n redis
kubectl logs -n redis deploy/redis-master
```

### CONFIG SET failed: NOAUTH Authentication required

Voce tentou configurar algo sem autenticar.

```
# Antes de qualquer comando, autentique:
AUTH <senha>
```

---

## Perguntas Frequentes

### Redis perde dados se reiniciar?

Depende:
- Sem persistencia: SIM, perde TUDO.
- Com RDB: perde no maximo alguns minutos (desde o ultimo snapshot).
- Com AOF: perde no maximo 1 segundo (appendfsync everysec).

### Redis e banco de dados principal?

NAO. Redis e um cache, nao um banco relacional. Dados importantes (pedidos, usuarios, pagamentos) devem ficar em PostgreSQL/MySQL. Redis e para dados temporarios, de sessao, ou que podem ser recriados.

### Quantas chaves o Redis suporta?

Milhoes. Depende da memoria RAM disponivel. Cada chave tem overhead de ~100 bytes, mais o valor.

### Posso usar Redis como fila?

Sim. Use `LPUSH` para adicionar e `BRPOP` para consumir (bloqueante). Para filas mais robustas, use RabbitMQ ou Kafka (que garantem entrega e persistem em disco).

---

## Boas Praticas

1. **Sempre defina TTL (EXPIRE)** — senao as chaves acumulam e a memoria enche.
2. **Nao use KEYS em producao** — ele bloqueia o Redis enquanto varre todas as chaves. Use SCAN.
3. **Defina maxmemory** — senao o Redis pode consumir toda a RAM do node e causar OOM.
4. **Escolha a politica de expulsao correta**:
   - `allkeys-lru`: remove as menos usadas (recomendado para cache)
   - `noeviction`: retorna erro (so use se nao puder perder dados)
5. **Nao armazene dados > 10MB por chave** — Redis nao e feito para blobs grandes. Use S3 para isso.

---

## Referencias

- [Documentacao oficial do Redis](https://redis.io/documentation)
- [Bitnami Redis Helm Chart](https://github.com/bitnami/charts/tree/main/bitnami/redis)
- [Lista completa de comandos Redis](https://redis.io/commands)
