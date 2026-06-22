terraform {
  source = "../../../../../../../monitoring/modules/observability/opencost"
}

include "root" {
  path = find_in_parent_folders()
}

include "monitoring" {
  path = "${get_terragrunt_dir()}/../root.hcl"
}

dependency "prometheus" {
  config_path = "../prometheus"
  mock_outputs = {
    prometheus_url_internal = "http://prometheus-server.monitoring.svc.cluster.local:80"
    prometheus_service_name = "prometheus-server"
    prometheus_namespace    = "monitoring"
  }
}

inputs = {
  opencost_release_name          = "opencost"
  opencost_chart_name            = "opencost"
  opencost_namespace             = "monitoring"
  opencost_chart_version         = "2.2.0"
  opencost_repository_url        = "https://opencost.github.io/opencost-helm-chart"
  opencost_prometheus_address    = "http://prometheus-server.monitoring.svc.cluster.local"
  opencost_cluster_id            = "aks-observability"
  opencost_resources_preset      = "small"
  opencost_replica_count         = 1

  # ==================================================================
  # PRECIFICACAO - AZURE (ativo)
  # ==================================================================
  # Para ativar, crie um Service Principal e preencha as credenciais:
  #
  #   az ad sp create-for-rbac \
  #     --name "opencost-pricing" \
  #     --role "Reader" \
  #     --scope "/subscriptions/00000000-0000-0000-0000-000000000000"
  #
  #   az provider register --namespace Microsoft.Pricing
  #
  # Depois descomente e preencha:
  # opencost_azure_enabled          = true
  # opencost_azure_subscription_id  = "00000000-0000-0000-0000-000000000000"
  # opencost_azure_client_id        = "00000000-0000-0000-0000-000000000000"
  # opencost_azure_tenant_id        = "00000000-0000-0000-0000-000000000000"
  # opencost_azure_client_secret    = "segredo-aqui"
  #
  # Obs: Para ambiente local (kind/minikube/orbstack) sem cloud,
  # deixe opencost_azure_enabled = false e os custos ficarao em $0.
  # Para testar com precos fixos, defina via env vars no values.yaml.

  # ==================================================================
  # PRECIFICACAO - AWS (referencia - comentado)
  # ==================================================================
  # O OpenCost detecta automaticamente quando roda em EKS.
  # Nao requer configuracao via Terraform, apenas permissoes IAM:
  # - AmazonEC2ReadOnlyAccess
  # - AWSPriceListServiceFullAccess
  #
  # Se estiver usando AWS, remova o opencost_azure_enabled acima
  # e garanta que o node role do EKS tenha as policies citadas.

  # ==================================================================
  # PRECIFICACAO - GCP (referencia - comentado)
  # ==================================================================
  # O OpenCost detecta automaticamente quando roda em GKE.
  # Nao requer configuracao via Terraform, apenas o escopo:
  # - https://www.googleapis.com/auth/cloud-platform
  #
  # Se estiver usando GKE, remova o opencost_azure_enabled acima
  # e garanta que os nodes tenham o escopo de cloud-platform.
}


