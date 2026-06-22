terraform {
  source = "../../../../../monitoring/modules/observability/namespace"
}

include {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  namespace_name = "monitoring"
}
