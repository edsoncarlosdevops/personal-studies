output "cluster_id" {
  description = "ID do cluster EKS"
  value       = aws_eks_cluster.this.id
}

output "cluster_endpoint" {
  description = "Endpoint do cluster EKS"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_name" {
  description = "Nome do cluster EKS"
  value       = aws_eks_cluster.this.name
}

output "cluster_certificate_authority" {
  description = "Certificate authority do cluster EKS"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "node_group_id" {
  description = "ID do node group do cluster EKS"
  value       = aws_eks_node_group.this.id
}

output "node_group_arn" {
  description = "ARN do node group do cluster EKS"
  value       = aws_eks_node_group.this.arn
}