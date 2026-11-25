###############################################################################
# Cluster IAM role
###############################################################################

resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

###############################################################################
# EKS cluster
###############################################################################

resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.cluster.arn
  tags     = var.tags

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_public_access  = var.endpoint_public_access
    endpoint_private_access = true
  }

  # Access entries instead of the old aws-auth ConfigMap. The identity running
  # Terraform (the GitHub Actions role) becomes cluster admin.
  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.cluster]
}

###############################################################################
# Node IAM role -- ECR read-only is the equivalent of AcrPull in AKS
###############################################################################

resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-node-role"
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ])

  role       = aws_iam_role.node.name
  policy_arn = each.value
}

###############################################################################
# Node groups -- same idea as system / user node pools in AKS
###############################################################################

resource "aws_eks_node_group" "system" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = var.system_node_group.name
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids
  version         = var.kubernetes_version
  ami_type        = var.ami_type
  instance_types  = var.system_node_group.instance_types
  disk_size       = var.system_node_group.disk_size
  tags            = var.tags

  scaling_config {
    desired_size = var.system_node_group.desired_size
    min_size     = var.system_node_group.min_size
    max_size     = var.system_node_group.max_size
  }

  labels = {
    role = "system"
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [aws_iam_role_policy_attachment.node]
}

resource "aws_eks_node_group" "user" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = var.user_node_group.name
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids
  version         = var.kubernetes_version
  ami_type        = var.ami_type
  instance_types  = var.user_node_group.instance_types
  disk_size       = var.user_node_group.disk_size
  tags            = var.tags

  scaling_config {
    desired_size = var.user_node_group.desired_size
    min_size     = var.user_node_group.min_size
    max_size     = var.user_node_group.max_size
  }

  labels = {
    role = "user"
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [aws_iam_role_policy_attachment.node]
}

###############################################################################
# Add-ons
###############################################################################

resource "aws_eks_addon" "addons" {
  for_each = toset(var.addons)

  cluster_name = aws_eks_cluster.eks.name
  addon_name   = each.value
  tags         = var.tags

  # coredns needs nodes to schedule on.
  depends_on = [aws_eks_node_group.system]
}

###############################################################################
# OIDC provider -- for IRSA, the AWS equivalent of AKS workload identity
###############################################################################

resource "aws_iam_openid_connect_provider" "oidc" {
  count = var.enable_oidc ? 1 : 0

  url            = aws_eks_cluster.eks.identity[0].oidc[0].issuer
  client_id_list = ["sts.amazonaws.com"]
  tags           = var.tags
}

###############################################################################
# Extra cluster admins (your own IAM user/role for kubectl)
###############################################################################

resource "aws_eks_access_entry" "admin" {
  for_each = toset(var.admin_principal_arns)

  cluster_name  = aws_eks_cluster.eks.name
  principal_arn = each.value
}

resource "aws_eks_access_policy_association" "admin" {
  for_each = toset(var.admin_principal_arns)

  cluster_name  = aws_eks_cluster.eks.name
  principal_arn = each.value
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.admin]
}
