locals {
  repo_root = "${get_parent_terragrunt_dir()}/../../.."

  azure_suffix = run_cmd("--terragrunt-quiet", "az", "storage", "account", "list",
    "--resource-group", "terraform-states",
    "--query", "[0].name",
    "--output", "tsv"
  )
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "azurerm" {
      features {
        resource_group {
          prevent_deletion_if_contains_resources = false
        }
      }
    }
  EOF
}

remote_state {
  backend = "azurerm"
  config = {
    resource_group_name  = "terraform-states"
    storage_account_name = local.azure_suffix
    container_name       = "terraform-state"
    key                  = "${path_relative_to_include()}/terraform.tfstate"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
