output "cluster_id" {
  value = aws_eks_cluster.eks.id
}

output "cluster_name" {
  value = aws_eks_cluster.eks.name
}

output "cluster_arn" {
  value = aws_eks_cluster.eks.arn
}

output "cluster_endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output "cluster_ca_certificate" {
  value = aws_eks_cluster.eks.certificate_authority[0].data
}

output "node_role_arn" {
  description = "IAM role the nodes run as. Already has ECR read-only (the AcrPull equivalent)."
  value       = aws_iam_role.node.arn
}

output "oidc_issuer_url" {
  value = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  description = "For IRSA trust policies. Null when enable_oidc = false."
  value       = var.enable_oidc ? aws_iam_openid_connect_provider.oidc[0].arn : null
}
