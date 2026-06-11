# ═══════════════════════════════════════════════════════════
# Namespace - Módulo Transicional (vazio)
# ═══════════════════════════════════════════════════════════
# Este módulo não gerencia mais recursos.
# Cada Helm chart cria seu próprio namespace via
# create_namespace = true, eliminando conflitos.
#
# Mantido apenas para compatibilidade com referências
# existentes no repositório.
# ═══════════════════════════════════════════════════════════

# Usa data source para verificar se existe (não falha)
data "kubernetes_namespace" "existing" {
  metadata {
    name = var.namespace_name
  }
}



