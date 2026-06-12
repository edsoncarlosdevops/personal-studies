#!/bin/bash
# =====================================================================
# setup-lab.sh - Configura ambiente de teste de auto-instrumentacao
# =====================================================================
# Script automatizado que:
#   1. Cria namespace otel-test
#   2. Sobe app de exemplo (api-pedidos com auto-instrumentation)
#   3. Gera trafego HTTP automaticamente
#   4. Verifica traces no Tempo
#
# [ATENCAO] O OTEL Operator e o recurso Instrumentation ja sao
# instalados via Terragrunt no modulo opentelemetry-operator.
# Nao e necessario aplicar manifests manuais de Instrumentation.
#
# Uso:
#   chmod +x setup-lab.sh
#   ./setup-lab.sh
#
# Para limpar depois:
#   kubectl delete namespace otel-test
#
# Estrutura de diretorios:
#   monitoring/
#     tests/
#       setup-lab.sh                       <- Script de automacao
#       apps/                              <- Apps de exemplo para teste
#         api-pedidos.yaml
# =====================================================================

set -e

NAMESPACE="otel-test"
APPS_DIR="apps"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=============================================="
echo "  Setup do Ambiente de Teste OTEL"
echo "=============================================="
echo "Namespace: $NAMESPACE"
echo ""

# -----------------------------------------------------------------
# Passo 1: Cria o namespace
# -----------------------------------------------------------------
echo "[1/4] Criando namespace $NAMESPACE..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# -----------------------------------------------------------------
# Passo 2: Sobe as aplicacoes de exemplo
# -----------------------------------------------------------------
echo ""
echo "[2/4] Subindo aplicacao de exemplo..."
kubectl apply -f $SCRIPT_DIR/$APPS_DIR/api-pedidos.yaml

echo ""
echo "Aguardando pod ficar pronto..."
echo "  - api-pedidos (auto-instrumentation Python)..."
kubectl wait --for=condition=ready pod -n $NAMESPACE -l app=api-pedidos --timeout=120s 2>/dev/null || \
  echo "    TIMEOUT - verifique manualmente com: kubectl get pods -n $NAMESPACE"

echo ""
echo "Pods rodando:"
kubectl get pods -n $NAMESPACE

# -----------------------------------------------------------------
# Passo 3: Gera trafego nas APIs
# -----------------------------------------------------------------
echo ""
echo "[3/4] Gerando trafego de teste..."
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

# -----------------------------------------------------------------
# Verificacao: Busca traces no Tempo
# -----------------------------------------------------------------
echo ""
echo "=============================================="
echo "  VERIFICACAO"
echo "=============================================="
echo ""
echo "[4/4] Aguardando 10s para processamento dos traces..."
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
    print()
    print('  NENHUM trace encontrado. Possiveis causas:')
    print('  1. O pod pode nao ter a annotation correta')
    print('  2. O Operator pode estar com erro (kubectl logs -n monitoring -l app.kubernetes.io/name=opentelemetry-operator)')
    print('  3. O init container pode ter falhado (kubectl describe pod -n $NAMESPACE -l app=api-pedidos)')
" 2>/dev/null

echo ""
echo "=============================================="
echo "  AMBIENTE PRONTO"
echo "=============================================="
echo ""
echo "Comandos uteis:"
echo "  Grafana:  kubectl -n monitoring port-forward svc/grafana 3000:80"
echo "  Prometheus: kubectl -n monitoring port-forward svc/prometheus-server 9090:80"
echo "  Logs API: kubectl logs -n $NAMESPACE -l app=api-pedidos"
echo "  Logs Operator: kubectl logs -n monitoring -l app.kubernetes.io/name=opentelemetry-operator"
echo ""
echo "Para limpar: kubectl delete namespace $NAMESPACE"
echo ""
