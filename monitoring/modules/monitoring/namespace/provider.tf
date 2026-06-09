# ═══════════════════════════════════════════════════════════
# Provider - Namespace
# ═══════════════════════════════════════════════════════════
# Necessário para criar o namespace no cluster K8s.
# O config_path é herdado do terragrunt.hcl raiz via generate.
# ═══════════════════════════════════════════════════════════

provider "kubernetes" {
  config_path = "~/.kube/config"
}
