# ═══════════════════════════════════════════════════════════
# Vault - Outputs Uteis
# ═══════════════════════════════════════════════════════════

output "vault_url_internal" {
  value       = "http://vault.${var.vault_namespace}.svc.cluster.local:8200"
  description = "URL interna do Vault (usada por aplicacoes no cluster)"
}

output "vault_ui_url" {
  value       = "http://vault.${var.vault_namespace}.svc.cluster.local:8200/ui"
  description = "URL da interface web do Vault"
}

output "vault_port_forward_command" {
  value       = "kubectl -n ${var.vault_namespace} port-forward svc/vault 8200:8200"
  description = "Comando para expor o Vault localmente (http://localhost:8200)"
}

output "vault_init_command" {
  value       = "kubectl exec -n ${var.vault_namespace} vault-0 -- vault operator init"
  description = "Comando para inicializar o Vault (gera chaves de unseal + token root)"
}

output "vault_status_command" {
  value       = "kubectl exec -n ${var.vault_namespace} vault-0 -- vault status"
  description = "Comando para verificar status do Vault (sealed ou unsealed)"
}

output "vault_unseal_example" {
  value       = "kubectl exec -n ${var.vault_namespace} vault-0 -- vault operator unseal <chave-1>"
  description = "Comando para desbloquear o Vault (repetir 3x com chaves diferentes)"
}

output "vault_namespace" {
  value       = var.vault_namespace
  description = "Namespace onde o Vault esta instalado"
}

output "vault_service_name" {
  value       = "vault"
  description = "Nome do service principal do Vault"
}
