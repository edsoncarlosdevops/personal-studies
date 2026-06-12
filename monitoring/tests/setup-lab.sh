#!/bin/bash
# =====================================================================
# setup-lab.sh - Configura ambiente de teste do OTEL Operator
# =====================================================================
# Este script automatiza a criacao do namespace de testes, aplicacao
# dos manifests (sidecar, instrumentation, apps), geracao de trafego
# e verificacao dos traces no Tempo.
#
# Uso:
#   chmod +x setup-lab.sh
#   ./setup-lab.sh
#
# Pre-requisitos:
#   - Cluster EKS rodando com a stack de monitoring
#   - OTEL Operator instalado no namespace monitoring
#   - kubectl configurado
# =====================================================================

set -e

NAMESPACE="otel-test"
BASE_DIR="$(dirname "$0")"

echo "=============================================="
echo "  Setup do Ambiente de Teste OTEL Operator"
echo "=============================================="

# -----------------------------------------------------------------
# Passo 1: Cria o namespace
# -----------------------------------------------------------------
echo ""
echo "[1/6] Criando namespace $NAMESPACE..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# -----------------------------------------------------------------
# Passo 2: Aplica os manifests do OTEL Operator
# -----------------------------------------------------------------
echo "[2/6] Aplicando OpenTelemetryCollector sidecar..."
kubectl apply -f $BASE_DIR/otel-sidecar.yaml

echo "[3/6] Aplicando Instrumentation Python..."
kubectl apply -f $BASE_DIR/python-instrumentation.yaml

# -----------------------------------------------------------------
# Passo 3: Aguarda os recursos ficarem prontos
# -----------------------------------------------------------------
echo "[4/6] Aguardando recursos do Operator..."
sleep 5
kubectl get opentelemetrycollector -n $NAMESPACE
kubectl get instrumentation -n $NAMESPACE

# -----------------------------------------------------------------
# Passo 4: Sobe as aplicacoes de exemplo
# -----------------------------------------------------------------
echo ""
echo "[5/6] Subindo aplicacoes de exemplo..."
kubectl apply -f $BASE_DIR/apps/api-pedidos.yaml
kubectl apply -f $BASE_DIR/apps/nginx-sidecar.yaml

echo ""
echo "Aguardando pods ficarem prontos..."
echo "  - api-pedidos (auto-instrumentation Python)..."
kubectl wait --for=condition=ready pod -n $NAMESPACE -l app=api-pedidos --timeout=120s 2>/dev/null || echo "    TIMEOUT - verificando manualmente"

echo "  - nginx-sidecar..."
kubectl wait --for=condition=ready pod -n $NAMESPACE -l app=nginx-sidecar --timeout=60s 2>/dev/null || echo "    TIMEOUT - verificando manualmente"

echo ""
echo "Pods rodando:"
kubectl get pods -n $NAMESPACE

# -----------------------------------------------------------------
# Passo 5: Gera trafego nas APIs
# -----------------------------------------------------------------
echo ""
echo "[6/6] Gerando trafego de teste..."

echo "  - API Pedidos (auto-instrumentation)..."
for i in $(seq 1 10); do
  kubectl exec -n monitoring deployment/grafana -- sh -c \
    "curl -s --connect-timeout 3 http://api-pedidos.$NAMESPACE.svc.cluster.local:5000/api/pedidos >/dev/null" 2>/dev/null
  kubectl exec -n monitoring deployment/grafana -- sh -c \
    "curl -s --connect-timeout 3 http://api-pedidos.$NAMESPACE.svc.cluster.local:5000/api/pedidos/1 >/dev/null" 2>/dev/null
  kubectl exec -n monitoring deployment/grafana -- sh -c \
    "curl -s --connect-timeout 3 -X POST http://api-pedidos.$NAMESPACE.svc.cluster.local:5000/api/checkout \
      -H 'Content-Type: application/json' -d '{\"cliente\":\"Maria\"}' >/dev/null" 2>/dev/null
  sleep 0.3
done

echo "  - Nginx..."
for i in $(seq 1 5); do
  kubectl exec -n monitoring deployment/grafana -- sh -c \
    "curl -s --connect-timeout 3 http://nginx-sidecar.$NAMESPACE.svc.cluster.local:80 >/dev/null" 2>/dev/null
  sleep 0.3
done

# -----------------------------------------------------------------
# Verificacao: Busca traces no Tempo
# -----------------------------------------------------------------
echo ""
echo "=============================================="
echo "  VERIFICACAO"
echo "=============================================="
echo ""
echo "Aguardando 10s para processamento dos traces..."
sleep 10

echo "Traces encontrados no Tempo:"
kubectl exec -n monitoring deployment/grafana -- sh -c \
  'curl -s "http://tempo:3100/api/search?limit=20"' 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
traces = data.get('traces', [])
print(f'Total de traces: {len(traces)}')
for t in traces[:10]:
    print(f'  {t.get(\"rootServiceName\",\"?\")} - {t.get(\"rootTraceName\",\"?\")} ({t.get(\"durationMs\",0)}ms)')
if not traces:
    print('  NENHUM trace encontrado. Verifique:')
    print('  - kubectl logs -n monitoring -l app.kubernetes.io/name=opentelemetry-operator')
    print('  - kubectl logs -n $NAMESPACE -l app=api-pedidos')
" 2>/dev/null

echo ""
echo "=============================================="
echo "  AMBIENTE PRONTO"
echo "=============================================="
echo ""
echo "Para acessar o Grafana:"
echo "  kubectl -n monitoring port-forward svc/grafana 3000:80"
echo "  http://localhost:3000"
echo ""
echo "Para limpar o ambiente:"
echo "  kubectl delete namespace $NAMESPACE"
echo ""
echo "Metricas no Prometheus:"
echo "  kubectl -n monitoring port-forward svc/prometheus-server 9090:80"
echo "  http://localhost:9090"
echo ""
