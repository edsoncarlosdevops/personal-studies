  # ═══════════════════════════════════════════════════════════
# ArgoCD - Helm Release (resiliente a destroy)
  # ═══════════════════════════════════════════════════════════
# O Helm cria o namespace automaticamente (create_namespace).
# Em destroy, os CRDs sao removidos via local-exec, evitando
# o erro "context deadline exceeded" e warnings de resource policy.
# ═══════════════════════════════════════════════════════════

data "kubernetes_secret" "argocd_admin" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = "argocd"
  }
}

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

  depends_on = [data.kubernetes_secret.argocd_admin]
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
      echo "🧹 Limpando recursos do ArgoCD antes do destroy..."
      kubectl delete crd applications.argoproj.io --ignore-not-found --wait=false 2>/dev/null || true
      kubectl delete crd applicationsets.argoproj.io --ignore-not-found --wait=false 2>/dev/null || true
      kubectl delete crd appprojects.argoproj.io --ignore-not-found --wait=false 2>/dev/null || true
      kubectl delete namespace argocd --ignore-not-found --wait=false 2>/dev/null || true
      echo "✅ Recursos do ArgoCD removidos"
    EOT
  }
}

