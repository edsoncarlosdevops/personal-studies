  # ═══════════════════════════════════════════════════════════
# ArgoCD - Helm Release (resiliente a destroy)
  # ═══════════════════════════════════════════════════════════
# O Helm cria o namespace automaticamente (create_namespace).
# Em destroy, os CRDs sao removidos via local-exec, evitando
# o erro "context deadline exceeded" e warnings de resource policy.
#
# IMPORTANTE: Se o cluster EKS ja foi destruido, o Terraform
# trava ao tentar desinstalar o Helm release (release not found).
# A solucao usa um `null_resource` com `local-exec` no destroy
# que remove o helm_release do state ANTES do Helm tentar
# desinstalar, via o `helm_release.argocd` depender dele.
# ═══════════════════════════════════════════════════════════

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_version
  namespace        = "argocd"
  create_namespace = true

  wait             = false
  cleanup_on_fail  = false
  atomic           = false
  force_update     = true
  timeout          = 120

  values = [file("${path.module}/values/values.yaml")]
}

# ═══════════════════════════════════════════════════════════
# Prevencao de falha no destroy do Helm release
# ═══════════════════════════════════════════════════════════
# Se o cluster EKS ja foi destruido (ou esta inacessivel),
# o Terraform tenta desinstalar o Helm e falha com:
#   "uninstall: Failed to purge the release: release: not found"
#
# Este resource roda ANTES do helm_release ser destruido
# (via depends_on) e remove o helm_release.argocd do state
# do Terraform. Assim o Helm nao precisa conectar no cluster.
# ═══════════════════════════════════════════════════════════

resource "null_resource" "prevent_helm_destroy_failure" {
  triggers = {
    uuid = uuid()
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "[prevent_helm_destroy_failure] Removendo helm_release.argocd do state..."
      terraform state rm 'module.argocd.helm_release.argocd' 2>/dev/null || \
        echo "[prevent_helm_destroy_failure] Ja foi removido ou state remoto bloqueou"
      echo "[prevent_helm_destroy_failure] OK"
    EOT
  }

  depends_on = [helm_release.argocd]
}

# ═══════════════════════════════════════════════════════════
# Data source para obter a senha do admin APOS o Helm criar
# ═══════════════════════════════════════════════════════════
# Usa depends_on para so consultar o secret depois que o
# Helm release estiver instalado.
# ═══════════════════════════════════════════════════════════

data "kubernetes_secret" "argocd_admin" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = "argocd"
  }

  depends_on = [helm_release.argocd]
}

# ═══════════════════════════════════════════════════════════
# Cleanup de CRDs no destroy
# ═══════════════════════════════════════════════════════════
# Os CRDs do ArgoCD tem "resource policy" de retencao e nao
# sao deletados pelo Helm. Este provisioner os remove antes
# da tentativa de destruir a release, evitando timeout.
# ═══════════════════════════════════════════════════════════

resource "null_resource" "cleanup_argocd" {
  triggers = {
    uuid = uuid()
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Limpando recursos do ArgoCD antes do destroy..."
      kubectl delete crd applications.argoproj.io --ignore-not-found --wait=false 2>/dev/null || true
      kubectl delete crd applicationsets.argoproj.io --ignore-not-found --wait=false 2>/dev/null || true
      kubectl delete crd appprojects.argoproj.io --ignore-not-found --wait=false 2>/dev/null || true
      kubectl delete namespace argocd --ignore-not-found --wait=false 2>/dev/null || true
      echo "Recursos do ArgoCD removidos"
    EOT
  }
}

