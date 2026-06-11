# OpenCost

## Visao Geral

OpenCost e uma ferramenta open-source para monitoramento de custos de Kubernetes. Ele mostra quanto cada namespace, deployment, pod ou serviço esta custando com base no consumo de CPU, memoria e armazenamento.

## O que ele faz no projeto

OpenCost se conecta ao Prometheus para obter metricas de uso de recursos e calcula o custo com base em precos da AWS (ou customizados).

## Arquitetura

```
OpenCost
    |
    +-> Prometheus
    |   (scrape: http://prometheus-server.monitoring.svc.cluster.local)
    |
    +-> APIs internas do cluster
    |   (kube-state-metrics)
    |
    v
Interface Web (porta 9003)
    |
    +-> Breakdown por:
        - Namespace
        - Deployment
        - Pod
        - Label
```

## Metricas de Custo

O OpenCost expoe metricas que o Prometheus pode raspar:

| Metrica | Descricao |
|---------|-----------|
| `node_cpu_hourly_cost` | Custo por CPU por hora |
| `node_gpu_hourly_cost` | Custo por GPU por hora |
| `node_ram_hourly_cost` | Custo por GB de RAM por hora |
| `pod_cost` | Custo total do pod |
| `deployment_cost` | Custo total do deployment |

## Como acessar

```bash
# Port-forward para UI do OpenCost
kubectl -n monitoring port-forward deployment/opencost 9003:9003

# Acessar
# http://localhost:9003
```

## O que ver na UI

1. **Allocation Dashboard** - Custo por namespace/deployment
2. **Assets** - Custo dos nos do cluster
3. **Settings** - Configurar precos, descontos, etc

## Ajuste de Precos

O OpenCost usa precos padrao da AWS. Voce pode customizar:

```yaml
# Configuracao via values.yaml
opencost:
  customPrices:
    cpu: "0.040"  # $/CPU/hour (t3.medium = ~$0.0416/h)
    memory: "0.005"  # $/GB/hour
    gpu: "0.70"  # $/GPU/hour
```

## Comandos Uteis

```bash
# Ver metricas de custo via API
kubectl -n monitoring port-forward deployment/opencost 9003:9003
curl http://localhost:9003/allocation/compute

# Ver custo por namespace
curl "http://localhost:9003/allocation/compute?window=1d&aggregate=namespace"

# Ver custo por label
curl "http://localhost:9003/allocation/compute?window=7d&aggregate=label:app"
```

## Referencias

- [Documentacao Oficial](https://www.opencost.io/docs/)
- [Helm Chart](https://github.com/opencost/opencost-helm-chart)
- [GitHub](https://github.com/opencost/opencost)
