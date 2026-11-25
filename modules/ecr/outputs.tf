output "ecr_arn" {
  value = aws_ecr_repository.ecr.arn
}

output "name" {
  value = aws_ecr_repository.ecr.name
}

output "repository_url" {
  description = "Registry URL. Prefix your image tags with this."
  value       = aws_ecr_repository.ecr.repository_url
}
