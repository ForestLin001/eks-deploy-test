# Deploy External Secrets Operator using helm_release
resource "helm_release" "external_secrets_operator" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  namespace  = var.eso_namespace
  create_namespace = true
  version = "0.18.0"

  skip_crds = false

  # Set values for the Helm chart
  values = [
    yamlencode({
      installCRDs = true

      webhook = {
        port = 10250
      }

      serviceAccount = {
        create = false
        name   = var.eso_service_account_name
      }

      # IRSA 方式，若你用的是 EKS，可在此关联 IAM 角色
      aws = {
        region = var.aws_region
      }

      replicaCount = 1
    })
  ]

  # Ensure the IAM role is created before deploying ESO
  depends_on = [
    aws_iam_role.external_secrets_role,
    module.eks
  ]
}

resource "null_resource" "wait_for_crd" {
  depends_on = [helm_release.external_secrets_operator]
  provisioner "local-exec" {
    command = "kubectl wait --for=condition=Established --timeout=60s crd/clustersecretstores.external-secrets.io"
  }
}

# 创建用于 External Secrets Operator 读取 SSM 参数的 IAM 策略
resource "aws_iam_policy" "ssm_read_policy" {
  name        = "${var.cluster_name}-external-secrets-ssm-read-policy"
  description = "Allows External Secrets Operator to read SSM Parameters"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.ssm_prefix}/*"
      }
    ]
  })
}

resource "aws_iam_role" "external_secrets_role" {
  name               = "${var.cluster_name}-external-secrets-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.this.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(data.aws_iam_openid_connect_provider.this.url, "https://", "")}:aud" : "sts.amazonaws.com",
            "${replace(data.aws_iam_openid_connect_provider.this.url, "https://", "")}:sub" : "system:serviceaccount:${var.eso_namespace}:${var.eso_service_account_name}"
          }
        }
      }
    ]
  })
}

# Attach the SSM read policy to the IAM role
resource "aws_iam_role_policy_attachment" "external_secrets_policy_attachment" {
  role       = aws_iam_role.external_secrets_role.name
  policy_arn = aws_iam_policy.ssm_read_policy.arn
}

# Data source to get OIDC provider ARN
data "aws_iam_openid_connect_provider" "this" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

resource "kubernetes_service_account" "external_secrets_sa" {
  metadata {
    name      = var.eso_service_account_name
    namespace = var.eso_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.external_secrets_role.arn
    }
  }
}