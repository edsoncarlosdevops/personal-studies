terraform {
  source = "../../../modules/app-rds"
}

include {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  environment = "dev"

  # RDS - Preencher com os valores reais do RDS
  db_endpoint = "CHANGE_ME.rds.amazonaws.com"
  db_port     = 5432
  db_name     = "appdb"
  db_username = "dbadmin"
  db_password = "CHANGE_ME"

  # Imagem Docker (buildar e publicar primeiro)
  app_image = "edsoncarlosdevops/app-rds:latest"

  # Replicas
  app_replicas = 1
}

