/*
  This file manages the creation and configuration of the AWS EKS cluster and its node groups using the official terraform-aws-eks module.
*/

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# Get EKS cluster data
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 20.11.0"

  cluster_name    = var.cluster_name
  cluster_version = var.eks_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  cluster_endpoint_public_access       = var.endpoint_public_access
  cluster_endpoint_private_access      = var.endpoint_private_access
  
  # 在 eks_managed_node_groups 中添加以下标签
  eks_managed_node_groups = {
    default = {
      desired_size   = 2
      max_size       = 5
      min_size       = 1
      instance_types = var.instance_types
      disk_size      = var.disk_size
      ami_type       = var.ami_type
      
      # 添加自动扩缩容标签
      tags = {
        Name = "${var.cluster_name}-node-group"
        "k8s.io/cluster-autoscaler/enabled" = "true"
        "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
      }
    }
  }

  # 可选：附加自定义 IAM 策略
  # iam_role_additional_policies = [aws_iam_policy.my_custom_policy.arn]

  # 设置认证模式为 API（仅使用 Access Entries）
  authentication_mode = "API"
  
  # 可选：将创建集群的身份添加为管理员
  enable_cluster_creator_admin_permissions = false
  
  # 配置 Access Entries
  access_entries = {
    # 为当前用户/角色添加集群管理员权限
    current_identity = {
      principal_arn = data.aws_caller_identity.current.arn
      policy_associations = {
        this = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
    
    # 为 GitHub Actions 角色添加集群管理员权限
    github-actions-role = {
      principal_arn = aws_iam_role.github_actions.arn
      policy_associations = {
        this = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    # 为构建/部署角色添加集群管理员权限
    # build-role = {
    #   principal_arn = "arn:aws:iam::440744252731:role/default-eks-node-group-20250609091413190100000001"
    #   policy_associations = {
    #     this = {
    #       policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
    #       access_scope = {
    #         type = "cluster"
    #       }
    #     }
    #   }
    # }
    
    # # 为超级管理员角色添加集群管理员权限
    # admin-role = {
    #   principal_arn = "arn:aws:iam::123456789012:role/admin-role"
    #   policy_associations = {
    #     this = {
    #       policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
    #       access_scope = {
    #         type = "cluster"
    #       }
    #     }
    #   }
    # }
    
    # 为节点角色添加必要的权限（EC2_LINUX 类型）
    # node-role = {
    #   principal_arn = "arn:aws:iam::123456789012:role/eks-node"
    #   type          = "EC2_LINUX"
    # }
    
    # 为开发者添加有限的命名空间访问权限
    #   developer-role = {
    #     principal_arn = "arn:aws:iam::123456789012:role/developer"
    #     policy_associations = {
    #       this = {
    #         policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
    #         access_scope = {
    #           type       = "namespace"
    #           namespaces = ["dev", "staging"]
    #         }
    #       }
    #     }
    #   }
  }

  # 添加 EKS 插件配置
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    # 添加 EBS CSI 驱动（用于持久化存储）
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }
}

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_iam_openid_connect_provider" "eks" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

# 获取EKS节点组角色名称（假设模块输出为 node_group_role_name）
data "aws_iam_role" "eks_node_role" {
  name = module.eks.eks_managed_node_groups["default"].iam_role_name
}

# 创建EBS CSI所需的IAM策略
resource "aws_iam_policy" "eks_node_ebs" {
  name        = "eks-node-ebs-policy"
  description = "EKS node group policy for EBS volume management"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVolume",
        "ec2:CreateTags",
        "ec2:DeleteVolume",
        "ec2:AttachVolume",
        "ec2:DetachVolume"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# 绑定策略到节点组角色
resource "aws_iam_role_policy_attachment" "eks_node_create_volume" {
  role       = data.aws_iam_role.eks_node_role.name
  policy_arn = aws_iam_policy.eks_node_ebs.arn
}
