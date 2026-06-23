########
# Helm #
########

resource "helm_release" "vault" {
  name             = var.vault_release_name
  chart            = var.vault_chart_name
  create_namespace = true
  wait             = false
  timeout          = 600
  namespace        = var.vault_namespace
  version          = var.vault_chart_version
  repository       = var.vault_repository_url
  force_update     = true
  upgrade_install  = true
  atomic           = true
  cleanup_on_fail  = true

  values = [
    templatefile("${path.module}/config/values.yaml", {
      vault_mode               = var.vault_mode
      vault_replica_count      = var.vault_replica_count
      vault_ui_enabled         = var.vault_ui_enabled
      vault_persistence_enabled = var.vault_persistence_enabled
      vault_persistence_size   = var.vault_persistence_size
    })
  ]
}

# ═══════════════════════════════════════════════════════════
# Inicializacao do Vault (passo manual apos instalacao)
# ═══════════════════════════════════════════════════════════
# Apos a instalacao, o Vault inicia "sealed".
# Execute os seguintes comandos manualmente:
#
# 1. kubectl exec -n vault vault-0 -- vault operator init
#    (guarde as 5 chaves de unseal e o token root)
#
# 2. kubectl exec -n vault vault-0 -- vault operator unseal <chave-1>
#    (repita 3 vezes)
#
# 3. kubectl exec -n vault vault-0 -- vault login <token-root>
#
# Opcional: kubectl port-forward -n vault svc/vault 8200:8200
# e acesse http://localhost:8200
# ═══════════════════════════════════════════════════════════
