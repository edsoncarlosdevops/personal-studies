# deploy/monitoring/grafana/terragrunt.hcl

terraform {
  # Aponta para a pasta modules que criamos no Passo 1
  source = "../../../modules/monitoring/grafana"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  grafana_release_name   = "grafana-local"
  grafana_chart_name     = "grafana"
  grafana_namespace      = "monitoring"
  grafana_chart_version  = "9.3.2" 
  grafana_repository_url = "https://grafana.github.io/helm-charts"
  
  # Valores Dummy para as variáveis do Istio que removemos (para o Terraform não reclamar)
  grafana_vs_name = "ignore"
  grafana_vs_dns  = "localhost"
  grafana_vs_port = 80
  
  grafana_replica_count = 1
}
