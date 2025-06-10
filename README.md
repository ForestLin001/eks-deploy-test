# DevOps EKS Deploy Test

本项目实验如何使用 Terraform 自动化部署 AWS EKS 集群、ECR 仓库，并通过 CI/CD 部署 Python 和 Go 微服务到 Kubernetes。

## 目录结构

    ```txt
    .
    ├── .github/
    │   └── workflows/
    │       └── eks-deploy.yaml         # GitHub Actions CI/CD 流程定义
    ├── Makefile                        # 常用自动化命令
    ├── README.md                       # 项目说明文档
    ├── check_aws_resources.sh          # 检查 AWS 资源的脚本
    ├── dev.tfvars                      # Terraform 变量文件（开发环境）
    ├── go-service/                     # Go 服务源码与 Dockerfile
    │   ├── Dockerfile
    │   ├── go.mod
    │   └── main.go
    ├── k8s/                            # Kubernetes 部署相关 YAML 文件
    │   ├── 00-namespace.yaml
    │   ├── go-deployment.yaml
    │   ├── ingress.yaml
    │   └── python-deployment.yaml
    ├── python-service/                 # Python 服务源码与 Dockerfile
    │   ├── Dockerfile
    │   ├── main.py
    │   └── requirements.txt
    └── terraform-eks-ecr/              # Terraform 相关配置
        ├── alb.tf
        ├── ecr.tf
        ├── eks.tf
        ├── github.tf
        ├── outputs.tf
        ├── provider.tf
        ├── variables.tf
        └── vpc.tf
    ```

## 快速开始

1. 初始化并部署基础设施：

    ```bash
    make tf-init
    make tf-apply TFVARS=dev.tfvars
    ```

2. 构建并推送镜像（推荐使用 Makefile 命令）：

    ```bash
    # 登录 ECR
    make login-ecr
    # 构建并推送 Python 镜像
    make push-python
    # 构建并推送 Go 镜像
    make push-go
    ```

3. 部署 Kubernetes 资源：

    ```bash
    make deploy
    ```

4. 访问服务：

    - 通过 Ingress Controller 暴露的地址访问服务。

## CI/CD

- 通过 `.github/workflows/eks-deploy.yaml` 实现自动化构建与部署。

## 其他

- 如需自定义资源或参数，请修改 `terraform-eks-ecr/` 下对应的 `.tf` 文件和 `k8s/` 下的 YAML 文件。
- 推荐使用 `Makefile` 简化常用操作。
- 可运行 `check_aws_resources.sh` 脚本检查 AWS 资源状态。
