# ═══════════════════════════════════════════════════════════
# Terragrunt Root - Monitoring
# ═══════════════════════════════════════════════════════════
# Raiz para os módulos de monitoramento.
# Herda configurações do pai (deploy/terragrunt.hcl)
# e adiciona dependências entre os módulos.
#
# Uso:
#   terragrunt run-all apply     # Aplica todos os módulos
#   terragrunt run-all destroy   # Destroi todos os módulos
#   terragrunt run-all output    # Output de todos os módulos
# ═══════════════════════════════════════════════════════════

# Herda configurações do pai (deploy/terragrunt.hcl)
include "root" {
  path = find_in_parent_folders()
}

# Inputs compartilhados entre todos os módulos de monitoring
inputs = {
  environment = "dev"
  cluster_name = "dev-eks-cluster"
}

