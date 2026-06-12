#!/bin/bash
# =====================================================================
# cleanup-all.sh - Limpeza completa do lab na ordem correta
# =====================================================================
# Evita o problema de dependencia circular onde o Terraform tenta
# destruir o EKS enquanto o Terragrunt ainda tem resources rodando.
#
# Ordem de destruicao:
#   1. Terragrunt (monitoring dentro do EKS)
#   2. Resources orfaos no EKS (se o Terragrunt falhou)
#   3. Terraform (infra AWS)
#
# Uso:
#   chmod +x cleanup-all.sh
#   ./cleanup-all.sh
# =====================================================================

set -e

echo "=============================================="
echo "  LIMPEZA COMPLETA DO LAB"
echo "=============================================="
echo ""

# -----------------------------------------------------------------
# Passo 1: Destroi monitoring dentro do EKS via Terragrunt
# -----------------------------------------------------------------
echo "[1/3] Destruindo monitoring via Terragrunt..."
if [ -d "monitoring/deploy" ]; then
  cd monitoring/deploy
  terragrunt destroy-all --auto-approve 2>/dev/null && \
    echo "  ✅ Terragrunt destruido com sucesso!" || \
    echo "  ⚠️  Terragrunt falhou (pode ser por dependencia ou state corrompido)"
  cd ../..
else
  echo "  ⚠️  Diretorio monitoring/deploy nao encontrado, pulando..."
fi

# -----------------------------------------------------------------
# Passo 2: Limpa resources orfaos no EKS
# -----------------------------------------------------------------
echo ""
echo "[2/3] Limpando resources orfaos no EKS..."
kubectl delete namespace otel-test --ignore-not-found 2>/dev/null && \
  echo "  ✅ Namespace otel-test removido" || \
  echo "  ⚠️  Namespace otel-test ja nao existia"

kubectl delete namespace monitoring --ignore-not-found 2>/dev/null && \
  echo "  ✅ Namespace monitoring removido" || \
  echo "  ⚠️  Namespace monitoring ja nao existia"

# Limpa states locais do Terragrunt que possam ter ficado
find . -path "*/monitoring/deploy/**/.terragrunt*" -delete 2>/dev/null || true
find . -path "*/monitoring/deploy/**/terraform.tfstate*" -delete 2>/dev/null || true
echo "  ✅ States locais limpos"

# -----------------------------------------------------------------
# Passo 3: Destroi infra AWS via Terraform
# -----------------------------------------------------------------
echo ""
echo "[3/3] Destruindo infra AWS..."
if [ -d "aws/eks_rds" ]; then
  cd aws/eks_rds
  terraform destroy -auto-approve 2>/dev/null && \
    echo "  ✅ Infra AWS destruida com sucesso!" || {
    echo "  ⚠️  Primeira tentativa falhou. Tentando novamente..."
    terraform destroy -auto-approve
  }
  cd ../..
elif [ -d "aws" ]; then
  # Tenta encontrar diretorios com terraform dentro de aws/
  for dir in aws/*/; do
    if [ -f "$dir/main.tf" ] || [ -f "$dir/terraform.tf" ]; then
      echo "  → Destruindo $dir..."
      cd "$dir"
      terraform destroy -auto-approve 2>/dev/null || true
      cd ../..
    fi
  done
else
  echo "  ⚠️  Diretorio aws nao encontrado, pulando..."
fi

echo ""
echo "=============================================="
echo "  ✅ LAB LIMPO COM SUCESSO!"
echo "=============================================="
echo ""
echo "Para verificar se sobrou algo no cluster:"
echo "  kubectl get namespaces"
echo "  kubectl get all --all-namespaces | grep -v kube-system | grep -v kube-public | grep -v kube-node-lease"
echo ""
