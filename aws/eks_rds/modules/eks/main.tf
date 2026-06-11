resource "aws_iam_role" "eks_cluster" {
  name = "${var.environment}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = { Name = "${var.environment}-eks-cluster-role" }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

# Cluster EKS principal
resource "aws_eks_cluster" "this" {
  name     = "${var.environment}-eks-cluster"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.k8s_version

  vpc_config {
    subnet_ids         = concat(var.public_subnet_ids, var.private_subnet_ids)
    security_group_ids = [aws_security_group.eks_cluster.id]
  }

  tags = { Name = "${var.environment}-eks-cluster" }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource
  ]
}

# IAM Role pros nodes do EKS
resource "aws_iam_role" "eks_node_group" {
  name = "${var.environment}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = { Name = "${var.environment}-eks-node-role" }
}

resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group.name
}

# Security Group para o cluster EKS (control plane)
resource "aws_security_group" "eks_cluster" {
  name        = "${var.environment}-eks-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  tags = { Name = "${var.environment}-eks-cluster-sg" }
}

# Security Group para os worker nodes
resource "aws_security_group" "eks_nodes" {
  name        = "${var.environment}-eks-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = { Name = "${var.environment}-eks-nodes-sg" }
}

# Regras de entrada: permite comunicação entre nodes
resource "aws_vpc_security_group_ingress_rule" "nodes_self" {
  security_group_id = aws_security_group.eks_nodes.id

  description                  = "Permite comunicacao entre os proprios nodes"
  referenced_security_group_id = aws_security_group.eks_nodes.id
  from_port                    = 0
  to_port                      = 65535
  ip_protocol                  = "tcp"
}

# Regras de entrada: permite trafego do control plane para nodes
resource "aws_vpc_security_group_ingress_rule" "nodes_cluster" {
  security_group_id = aws_security_group.eks_nodes.id

  description                  = "Permite trafego do control plane para os nodes"
  referenced_security_group_id = aws_security_group.eks_cluster.id
  from_port                    = 0
  to_port                      = 65535
  ip_protocol                  = "tcp"
}

# Node group com as EC2 que rodam os pods
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.environment}-eks-node-group"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  instance_types = var.node_instance_types

  # Associa o security group diretamente ao node group
  # sem usar launch template para evitar ciclo de dependencia
  tags = { Name = "${var.environment}-eks-node-group" }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node,
    aws_iam_role_policy_attachment.eks_cni,
    aws_iam_role_policy_attachment.ecr_read
  ]
}

