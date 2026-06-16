# Root terragrunt for dev environment
# Allows running terragrunt commands from this directory

include {
  path = find_in_parent_folders()
}
