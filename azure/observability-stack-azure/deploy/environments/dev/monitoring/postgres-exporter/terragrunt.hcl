terraform {
  source = "../../../../../monitoring/modules/monitoring/postgres-exporter"
}

include "root" {
  path = find_in_parent_folders()
}

include "monitoring" {
  path = "${get_terragrunt_dir()}/../terragrunt.hcl"
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
