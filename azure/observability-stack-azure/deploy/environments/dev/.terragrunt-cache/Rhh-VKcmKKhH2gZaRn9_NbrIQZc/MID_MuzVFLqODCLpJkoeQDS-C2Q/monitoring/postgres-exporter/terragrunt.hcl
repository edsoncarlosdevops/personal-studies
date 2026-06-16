terraform {
  source = "../../../../../monitoring/modules/monitoring/postgres-exporter"
}

include {
  path = find_in_parent_folders()
}

dependencies {
  paths = ["../../aks", "../prometheus"]
}

dependency "aks" {
  config_path = "../../aks"
}

dependency "prometheus" {
  config_path = "../prometheus"
}

dependency "postgresql" {
  config_path = "../../postgresql"
}

inputs = {
  release_name   = "postgres-exporter"
  chart_version  = "6.0.0"
  namespace      = "monitoring"
  db_host        = dependency.postgresql.outputs.server_fqdn
  db_user        = dependency.postgresql.outputs.admin_user
  db_password    = "P@ssw0rd1234!"
  db_name        = dependency.postgresql.outputs.database_name
}
