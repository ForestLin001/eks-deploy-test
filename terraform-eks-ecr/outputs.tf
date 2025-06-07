/*
  This file defines Terraform output variables 
  for exposing key resource attributes.
*/
output "cluster_name" {
  value = module.eks.cluster_name
}
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ecr_repo_urls" {
  description = "ECR repository URLs for all services"
  value = { for name, repo in aws_ecr_repository.service : name => repo.repository_url }
}

output "github_oidc_role_arn" {
  value = aws_iam_role.github_actions.arn
}