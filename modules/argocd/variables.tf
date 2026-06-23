###############################
# ArgoCD - Input Variables     #
###############################
#
# Todas as variaveis que o modulo do ArgoCD expoe para quem for usar.
# Siga o padrao: prefixo argocd_ para facilitar auto-complete no IDE.

# Contexto do Cluster
# Usado para identificar em qual ambiente estamos.
# Ex: local, dev, staging, prod
variable "context" {
  type        = string
  description = "Contexto do cluster (ex: local, dev, prod)"
  default     = "local"
}

# Nome do Release
# Nome do release Helm. Vira o nome do deployment no Kubernetes.
# Se voce tiver multiplos ArgoCD no mesmo cluster (nao recomendado),
# mude este nome para evitar conflito.
variable "argocd_release_name" {
  type        = string
  description = "Nome do release Helm do ArgoCD"
  default     = "argocd"
}

# Nome do Chart Helm
# O chart oficial do ArgoCD se chama "argo-cd".
# Nao mude a menos que esteja usando um fork proprio.
variable "argocd_chart_name" {
  type        = string
  description = "Nome do chart Helm do ArgoCD"
  default     = "argo-cd"
}

# Namespace
# Namespace onde o ArgoCD sera instalado.
# Por convencao, usa-se o namespace "argocd".
# Se mudar, lembre de atualizar os comandos de troubleshooting.
variable "argocd_namespace" {
  type        = string
  description = "Namespace onde o ArgoCD sera instalado"
  default     = "argocd"
}

# URL do Repositorio Helm
# Repositorio oficial do ArgoCD Helm chart.
# Mantido pelo time do ArgoCD no GitHub.
variable "argocd_repository_url" {
  type        = string
  description = "URL do repositorio Helm do ArgoCD"
  default     = "https://argoproj.github.io/argo-helm"
}

# Versao do Chart Helm
# Versao do chart argo-cd.
# Consulte versoes disponiveis em:
#   helm repo add argo https://argoproj.github.io/argo-helm
#   helm search repo argo/argo-cd --versions
variable "argocd_chart_version" {
  type        = string
  description = "Versao do chart Helm do ArgoCD (consulte helm search repo para listar)"
  default     = "7.8.1"
}

# Tipo do Service do Server
# Como o ArgoCD Server sera exposto dentro do cluster.
# Opcoes:
#   ClusterIP  - acessivel apenas dentro do cluster (recomendado com Ingress)
#   NodePort   - acessivel via IP do node em porta aleatoria
#   LoadBalancer - cria um Load Balancer (cloud) - cuidado com custos
#
# Recomendacao:
#   Dev/Lab: ClusterIP + Ingress
#   Producao: ClusterIP + Ingress (com autenticacao)
#   Teste rapido sem Ingress: LoadBalancer (mas lembre de derrubar)
variable "argocd_server_service_type" {
  type        = string
  description = "Tipo do Service do ArgoCD Server (ClusterIP, NodePort, LoadBalancer)"
  default     = "ClusterIP"
}

# Dominio (para Ingress)
# Dominio usado para acessar o ArgoCD via Ingress.
# Ex: argocd.dev.local, argocd.meudominio.com
# Usado no values.yaml para configurar o host do Ingress.
variable "argocd_domain" {
  type        = string
  description = "Dominio para acessar o ArgoCD via Ingress (ex: argocd.dev.local)"
  default     = "argocd.dev.local"
}

# Habilitar Ingress
# Se true, cria um Ingress para expor o ArgoCD Server externamente.
# Requer um Ingress Controller instalado (nginx-ingress, traefik, etc).
#
# Se false, voce precisara de port-forward ou LoadBalancer para acessar.
variable "argocd_ingress_enabled" {
  type        = bool
  description = "Habilita criacao de Ingress para o ArgoCD"
  default     = true
}

# Classe do Ingress
# Nome da ingress class que o Ingress Controller usa.
# Para nginx-ingress: "nginx"
# Para traefik: "traefik"
# Para Kong: "kong"
#
# Se vazio, usa a ingress class default do cluster.
variable "argocd_ingress_class" {
  type        = string
  description = "Nome da ingress class (ex: nginx, traefik)"
  default     = "nginx"
}

# Habilitar TLS no Ingress
# Se true, configura certificado TLS no Ingress.
# Requer um certificado valido (pode ser auto-assinado ou Lets Encrypt via cert-manager).
# Se false, o Ingress sera HTTP apenas (nao recomendado para producao).
variable "argocd_tls_enabled" {
  type        = bool
  description = "Habilita TLS (HTTPS) no Ingress do ArgoCD"
  default     = false
}
