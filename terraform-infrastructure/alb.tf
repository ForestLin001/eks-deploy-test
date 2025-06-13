/*
  This file contains resources related to AWS Application Load 
  Balancer (ALB) and ALB Ingress Controller for EKS.
*/
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.7.1"

  create_namespace = false

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
}

resource "kubernetes_service_account" "aws_lb_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_ingress.arn
    }
  }
}

# ALB Ingress Controller IAM Role
resource "aws_iam_role" "alb_ingress" {
  name = "${var.cluster_name}-alb-ingress-controller-role"

  assume_role_policy = data.aws_iam_policy_document.alb_assume_role.json
}

data "aws_iam_policy_document" "alb_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}

# 创建更详细的ALB控制器策略
resource "aws_iam_policy" "alb_controller_policy" {
  name        = "${var.cluster_name}-AWSLoadBalancerControllerIAMPolicy"
  description = "Policy for AWS Load Balancer Controller"
  
  # 这里使用了更详细的策略，比简单的ELBFullAccess更安全
  policy = file("${path.module}/policies/alb-controller-policy.json")
}

resource "aws_iam_role_policy_attachment" "alb_policy_attach" {
  role       = aws_iam_role.alb_ingress.name
  policy_arn = aws_iam_policy.alb_controller_policy.arn
}