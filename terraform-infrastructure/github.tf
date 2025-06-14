/*
  This file contains IAM resources and OIDC provider 
  configuration for GitHub Actions integration.
*/

# GitHub Actions OIDC Provider
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
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
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
          },
          StringLike = {
            "token.actions.githubusercontent.com:sub": "repo:${var.github_repo}:*"
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
}

# 创建自定义 EKS 访问策略
resource "aws_iam_policy" "eks_deployment_policy" {
  name        = "${var.project_name}-eks-deployment-policy"
  description = "Policy for GitHub Actions to deploy to EKS"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:UpdateClusterConfig",
          "eks:UpdateNodegroupConfig"
        ],
        Resource = "*"
      }
    ]
  })
}

# 附加自定义策略到 GitHub Actions 角色
resource "aws_iam_role_policy_attachment" "eks_deployment_access" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.eks_deployment_policy.arn
}

