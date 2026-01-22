terraform {
  source = "../../../modules/monitoring/opencost"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  opencost_release_name   = "opencost-local"
  opencost_chart_name     = "opencost"
  opencost_namespace      = "monitoring" # Mesmo namespace do Prometheus facilita
  
  # Versão compatível recente (ajuste se seu repo tiver outra fixa)
  opencost_chart_version  = "2.2.0" 
  opencost_repository_url = "https://opencost.github.io/opencost-helm-chart"

  # CONEXÃO COM O PROMETHEUS:
  # Formato: http://<nome-do-servico>.<namespace>.svc.cluster.local
  # Como usamos release_name="prometheus-local" no passo anterior, o service padrão é:
  opencost_prometheus_address = "http://prometheus-local-server.monitoring.svc.cluster.local"
  
  opencost_cluster_id       = "mac-m2-lab"
  opencost_resources_preset = "small"
}