########
# Helm #
########

# ArgoCD - Helm Release (resiliente a destroy)
#
# Este recurso instala o ArgoCD via Helm chart.
# O Helm cria o namespace automaticamente (create_namespace = true).
#
# POR QUE `force_update = true`?
#   Se voce alterar algo no values.yaml (ex: mudou uma URL de ingress),
#   o Helm precisa aplicar a mudanca. O force_update=true garante que
#   ele substitua a release existente sem precisar destruir e recriar.
#
# POR QUE `wait = false`?
#   O ArgoCD tem varios componentes (server, controller, repo-server, redis).
#   O wait=true faria o Helm esperar ate TODOS estarem prontos, o que pode
#   levar minutos e dar timeout. Com wait=false, o Terraform aceita que
#   os pods estao sendo criados e prossegue.
#
# POR QUE `atomic = false`?
#   Se o deploy falhar, atomic=true faria rollback automatico (bom em teoria,
#   mas as vezes o rollback tambem falha e o estado fica inconsistente).
#   atomic=false mantem os recursos criados para debug manual.
#
# POR QUE `cleanup_on_fail = false`?
#   Similar ao atomic: se falhar, mantem os pods/deployments para voce
#   inspecionar logs e entender o erro.

resource "helm_release" "argocd" {
  name             = var.argocd_release_name
  chart            = var.argocd_chart_name
  repository       = var.argocd_repository_url
  version          = var.argocd_chart_version
  namespace        = var.argocd_namespace
  create_namespace = true

  wait             = false
  cleanup_on_fail  = false
  atomic           = false
  force_update     = true
  timeout          = 120

  # Arquivo de valores (config) do ArgoCD
  # O arquivo config/values.yaml contem todas as customizacoes.
  # Usamos templatefile() para permitir variaveis do Terraform
  # dentro do YAML (ex: ${argocd_server_service_type}).
  values = [
    templatefile("${path.module}/config/values.yaml", {
      argocd_server_service_type = var.argocd_server_service_type
      argocd_domain              = var.argocd_domain
      argocd_ingress_enabled     = var.argocd_ingress_enabled
      argocd_ingress_class       = var.argocd_ingress_class
      argocd_tls_enabled         = var.argocd_tls_enabled
    })
  ]
}

# Prevencao de falha no destroy do Helm release
#
# PROBLEMA:
# Se o cluster Kubernetes ja foi destruido (ou esta inacessivel),
# o Terraform tenta desinstalar o Helm release e falha com:
#   "uninstall: Failed to purge the release: release: not found"
#
# Isso acontece porque o Terraform nao consegue conectar no cluster
# para executar o helm uninstall, mas o recurso ainda esta no state.
# O Terraform entra em loop tentando destruir e falhando.
#
# SOLUCAO:
# Este resource roda ANTES do helm_release ser destruido
# (via depends_on) e remove o helm_release.argocd do state
# do Terraform. Assim o Helm nao precisa conectar no cluster.
# Como o resource esta sendo destruido e nao tem cluster para conectar,
# o state removal e suficiente - o recurso nunca vai existir de fato.

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

# Data source para obter a senha do admin APOS o Helm criar
#
# O ArgoCD gera automaticamente um secret com a senha do admin
# no namespace argocd: argocd-initial-admin-secret.
#
# Usamos depends_on para so consultar o secret depois que o
# Helm release estiver instalado. Caso contrario, o Terraform
# tentaria ler o secret antes de ele existir e falharia.

data "kubernetes_secret" "argocd_admin" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = var.argocd_namespace
  }

  depends_on = [helm_release.argocd]
}

# Cleanup de CRDs no destroy
#
# PROBLEMA:
# O ArgoCD instala CRDs (Custom Resource Definitions) como:
#   - applications.argoproj.io
#   - applicationsets.argoproj.io
#   - appprojects.argoproj.io
#
# Esses CRDs tem "resource policy" de retencao no Helm chart,
# ou seja, o Helm NAO os deleta quando a release e destruida.
# O resultado e que o Terraform fica esperando os CRDs sumirem,
# da timeout, e o destroy falha.
#
# SOLUCAO:
# Este provisioner executa kubectl delete crd antes do Helm
# tentar destruir a release. Os CRDs sao removidos manualmente
# e o Helm nao encontra mais recursos para travar.
#
# Por que --wait=false?
#   Para nao esperar a remocao completa. Alguns CRDs podem ter
#   finalizers que demoram. O --wait=false dispara a delecao
#   e continua, evitando timeout.

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
      kubectl delete namespace ${var.argocd_namespace} --ignore-not-found --wait=false 2>/dev/null || true
      echo "Recursos do ArgoCD removidos"
    EOT
  }
}
