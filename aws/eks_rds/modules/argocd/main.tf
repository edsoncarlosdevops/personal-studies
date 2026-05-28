terraform {
  required_providers {
    null = {
      source = "hashicorp/null"
      version = "~> 3.0"
    }
    local = {
      source = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

resource "null_resource" "install_argocd" {
  triggers = {
    version = var.argocd_version
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws eks update-kubeconfig --region us-east-1 --name ${var.eks_cluster_name} --kubeconfig /tmp/kubeconfig-argocd
      export KUBECONFIG=/tmp/kubeconfig-argocd

      kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

      helm repo add argo https://argoproj.github.io/argo-helm 2>/dev/null || true
      helm upgrade --install argocd argo/argo-cd \
        --version ${var.argocd_version} \
        --namespace argocd \
        -f ${path.module}/values/values.yaml
    EOT
  }
}
