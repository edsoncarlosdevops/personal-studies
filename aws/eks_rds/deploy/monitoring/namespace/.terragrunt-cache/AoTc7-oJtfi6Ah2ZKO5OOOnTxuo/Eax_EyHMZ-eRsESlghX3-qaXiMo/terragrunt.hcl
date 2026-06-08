terraform {
  source = "../../../../../monitoring/modules/monitoring/namespace"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  namespace_name = "monitoring"
}
