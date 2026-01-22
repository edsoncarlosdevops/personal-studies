terraform {
  # Aponta para a pasta modules que criamos acima
  source = "../../../modules/monitoring/prometheus"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  context                   = "local"
  prometheus_release_name   = "prometheus-local"
  prometheus_chart_name     = "prometheus"
  prometheus_namespace      = "monitoring"
  
  # Versão extraída do seu código original
  prometheus_chart_version  = "27.1.0"
  prometheus_repository_url = "https://prometheus-community.github.io/helm-charts"

  # Valores Dummy para as variáveis de VS/Ingress (sem Istio)
  prometheus_vs_name = "ignore"
  prometheus_vs_dns  = "localhost"
  prometheus_vs_port = 80

  prometheus_replica_count = 1
}