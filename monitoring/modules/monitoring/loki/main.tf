# ═══════════════════════════════════════════════════════════
# Loki - Helm Release
# ═══════════════════════════════════════════════════════════
#
# NOTAS IMPORTANTES:
# 1. wait = false: O Loki pode demorar para ficar ready (download de
#    imagem, provisionamento de volume). Não travar o deploy evita
#    timeouts desnecessários.
#
# 2. force_update = true: Permite que o Helm force o upgrade mesmo
#    se a release estiver em estado "failed". Evita o erro
#    "cannot re-use a name that is still in use".
#
# 3. cleanup_on_fail = true: Se o install/upgrade falhar, o Helm
#    automaticamente faz rollback. Importante para não deixar a
#    release em estado quebrado.
#
# 4. timeout = 600: Aumentado para 10 minutos para dar tempo de
#    provisionamento de PVC (EBS gp2) e download de imagens.

resource "helm_release" "loki" {
  name             = var.loki_release_name
  chart            = var.loki_chart_name
  create_namespace = false
  wait             = false
  namespace        = var.loki_namespace
  version          = var.loki_chart_version
  repository       = var.loki_repository_url
  timeout          = 600
  force_update     = true
  cleanup_on_fail  = true

  values = [
    templatefile("${path.module}/config/values.yaml", {
      loki_pvc_size = "10Gi"
    })
  ]
}