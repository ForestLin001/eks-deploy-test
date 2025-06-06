output "python_ecr_repo_url" {
  value = aws_ecr_repository.python.repository_url
}

output "go_ecr_repo_url" {
  value = aws_ecr_repository.go.repository_url
}

output "github_oidc_role_arn" {
  value = aws_iam_role.github_actions.arn
}
