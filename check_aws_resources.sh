#!/bin/bash

# 检查 AWS 资源脚本
# 用于检测 EKS 集群、VPC、OIDC provider 是否存在且可用
# 使用前请确保已配置好 AWS CLI 凭证和 region

REGION="ap-southeast-1"           # 替换为你的 AWS 区域
CLUSTER_NAME="your-eks-cluster"   # 替换为你的 EKS 集群名
VPC_NAME="your-vpc-name"          # 替换为你的 VPC 名称
OIDC_URL="your-oidc-url"          # 替换为你的 OIDC provider URL（如 https://oidc.eks.ap-southeast-1.amazonaws.com/id/xxxxxxx）

# 检查 EKS 集群是否存在
function check_eks() {
  echo "检查 EKS 集群: $CLUSTER_NAME ..."
  aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "EKS 集群已存在"
  else
    echo "EKS 集群不存在或无法访问"
  fi
}

# 检查 VPC 是否存在
function check_vpc() {
  echo "检查 VPC: $VPC_NAME ..."
  VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$VPC_NAME" --region "$REGION" --query 'Vpcs[0].VpcId' --output text)
  if [ "$VPC_ID" != "None" ]; then
    echo "VPC 已存在，ID: $VPC_ID"
  else
    echo "VPC 不存在"
  fi
}

# 检查 OIDC provider 是否存在
function check_oidc() {
  echo "检查 OIDC provider: $OIDC_URL ..."
  OIDC_ARN=$(aws iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[*].Arn' --output text)
  FOUND=0
  for arn in $OIDC_ARN; do
    URL=$(aws iam get-open-id-connect-provider --open-id-connect-provider-arn $arn --query 'Url' --output text)
    if [ "$URL" == "$OIDC_URL" ]; then
      echo "OIDC provider 已存在，ARN: $arn"
      FOUND=1
      break
    fi
  done
  if [ $FOUND -eq 0 ]; then
    echo "OIDC provider 不存在"
  fi
}

# 主流程
check_eks
check_vpc
check_oidc