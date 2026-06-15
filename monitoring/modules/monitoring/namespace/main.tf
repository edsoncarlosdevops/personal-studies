# ═══════════════════════════════════════════════════════════
# Namespace - Módulo Transicional (vazio)
# ═══════════════════════════════════════════════════════════
# Este modulo nao gerencia mais recursos diretamente.
# Cada Helm chart cria seu proprio namespace via
# create_namespace = true, eliminando conflitos de dependencia.
#
# Mantido apenas para compatibilidade com referencias
# existentes no repositorio (outputs e data sources).
# ═══════════════════════════════════════════════════════════

# Usa data source para verificar se existe (nao falha)
data "kubernetes_namespace" "existing" {
  metadata {
    name = var.namespace_name
  }
}

