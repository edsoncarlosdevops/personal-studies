# Promtail - Coleta de Logs para Loki

## Funcao

Coleta logs do stdout/stderr dos pods do Kubernetes e envia para o Loki.
Funciona com qualquer aplicacao sem modificar codigo.

## Fluxo esperado

```
Pod (stdout/stderr) -> /var/log/pods/ -> Promtail (DaemonSet) -> Loki (:3100)
```

## Labels no Loki

- `namespace` - namespace do pod
- `pod` - nome do pod
- `container` - nome do container

## Por que Promtail e nao OTel para logs?

O OTel e excelente para **traces** e **metricas**, mas para logs:
- Precisa de bibliotecas extras na app
- Exige modificar o codigo para configurar handler OTel
- A auto-instrumentation nao captura logs automaticamente

O Promtail simplesmente le o stdout dos containers e envia ao Loki.
Funciona com qualquer linguagem, qualquer app, sem mudar nada.

## Comandos para debug

```bash
# Ver config gerada pelo chart
kubectl exec -n monitoring promtail-XXXX -- cat /etc/promtail/promtail.yaml

# Ver se os volumes estao montados
kubectl exec -n monitoring promtail-XXXX -- ls /var/log/pods/

# Ver targets detectados
kubectl exec -n monitoring promtail-XXXX -- wget -qO- http://localhost:3101/targets

# Ver metricas
kubectl exec -n monitoring promtail-XXXX -- wget -qO- http://localhost:3101/metrics | grep promtail_read_bytes

# Logs do Promtail
kubectl logs -n monitoring -l app.kubernetes.io/name=promtail --tail=50
```

## Para reinstalar (se travar)

```bash
# Liberar locks do Helm
kubectl get secrets -n monitoring | grep 'sh.helm' | awk '{print $1}' | xargs kubectl delete secret -n monitoring

# Instalar via Helm direto
helm upgrade --install promtail grafana/promtail \
  --namespace monitoring \
  --version 6.16.6 \
  -f monitoring/modules/monitoring/promtail/config/values.yaml
```

## Arquivos do modulo

- `main.tf` - Recurso helm_release
- `variables.tf` - Variaveis (release_name, namespace, etc)
- `config/values.yaml` - **Valores Helm (precisa de correcao, ver PROBLEMAS abaixo)**
- `outputs.tf` - Outputs

## PROBLEMAS CONHECIDOS (PENDENTE)

### 1. clients[0].url incorreta
O chart usa `loki-gateway` como URL padrao, mas desabilitamos o gateway.
```
Atual: http://loki-gateway/loki/api/v1/push
Deveria: http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push
```
**Testar:** `helm template promtail grafana/promtail -f values.yaml` e verificar
se `config.lokiAddress` aparece no lugar de `loki-gateway`.

### 2. Permissoes RBAC
Verificar se o ServiceAccount `promtail` tem ClusterRole com permissao
para listar pods (necessario para kubernetes_sd_configs).

### 3. Volume /var/log/pods
Confirmar se o volume hostPath esta montado corretamente.

### 4. Loki canary
Ja desabilitado no modulo do Loki (testing.enabled=false).
Confirmar se o pod loki-canary nao existe mais.

### 5. Dashboard Grafana
Criar novo dashboard com queries corretas de Loki, Prometheus e Tempo.
O dashboard atual pode estar apontando para labels que nao existem mais.
