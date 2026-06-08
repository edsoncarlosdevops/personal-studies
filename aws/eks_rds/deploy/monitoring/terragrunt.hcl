# ═══════════════════════════════════════════════════════════
# Terragrunt Root - Monitoring
# ═══════════════════════════════════════════════════════════
# Arquivo raiz para permitir comandos run-all nos módulos
# de monitoring (deploy, destroy, output, etc.)
#
# Uso:
#   terragrunt run-all apply     # Aplica todos os módulos
#   terragrunt run-all destroy   # Destroi todos os módulos
#   terragrunt run-all output    # Output de todos os módulos
# ═══════════════════════════════════════════════════════════

# Configurações que os módulos filhos herdam via include
# (os módulos filhos usam: include { path = find_in_parent_folders() })

# Sem configurações - apenas para ser um ponto de entrada
# para o comando 'terragrunt run -- run-all'

