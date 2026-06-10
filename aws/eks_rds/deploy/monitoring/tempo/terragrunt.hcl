terraform {
  source = "../../../../../monitoring/modules/monitoring/tempo"
}

include {
  path = find_in_parent_folders("root.hcl")
}

# Depende do namespace ser criado primeiro
dependencies {
  paths = ["../namespace"]
}

dependency "namespace" {
  mock_outputs = {
    namespace_name = "monitoring"
  }
  config_path = "../namespace"
}

inputs = {
  tempo_release_name   = "tempo"
  tempo_chart_name     = "tempo"
  tempo_namespace      = "monitoring"
  tempo_chart_version  = "1.7.1"
  tempo_repository_url = "https://grafana.github.io/helm-charts"
}
