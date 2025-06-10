/*
  This file contains IAM resources and OIDC provider 
  configuration for GitHub Actions integration.
*/

# 尝试获取现有的GitHub Actions OIDC Provider
data "aws_iam_openid_connect_provider" "existing_github" {
  # 使用try函数避免在Provider不存在时报错
  url = try(module.eks.cluster_oidc_issuer_url, "")
}

# 本地变量，用于判断OIDC Provider是否存在
locals {
  oidc_provider_exists = length(data.aws_iam_openid_connect_provider.existing_github) > 0 ? true : false
  oidc_provider_arn    = local.oidc_provider_exists ? data.aws_iam_openid_connect_provider.existing_github.arn : aws_iam_openid_connect_provider.github[0].arn
}

# GitHub Actions OIDC Provider - 仅在不存在时创建
resource "aws_iam_openid_connect_provider" "github" {
  count = local.oidc_provider_exists ? 0 : 1
  
  url = module.eks.cluster_oidc_issuer_url
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0afd10df6"]
}

# Create IAM role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-github-actions-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub" = "repo:*/*:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}

# Attach ECR and EKS policies to GitHub Actions role
resource "aws_iam_role_policy_attachment" "ecr_full_access" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_role_policy_attachment" "eks_access" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  depends_on = [module.eks]
}

