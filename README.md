# DevOps EKS 部署测试项目

本项目演示如何使用 Terraform 自动化部署 AWS EKS 集群、ECR 仓库，并通过 CI/CD 流程将 Python 和 Go 微服务部署到 Kubernetes 集群中，支持多环境（开发、测试、生产）部署策略。

## 项目特点

- 基于 Terraform 的基础设施即代码 (IaC)
- 多环境部署支持 (dev/test/prod)
- 自动化的 CI/CD 流程 (GitHub Actions)
- 微服务架构示例 (Python/Go)
- 基于模板的 Kubernetes 资源生成
- 使用 AWS ALB Ingress Controller 进行流量路由

## 目录结构

```txt
.
├── .github/workflows/         # GitHub Actions CI/CD 工作流定义
├── docs/                      # 项目文档
├── envs/                      # 环境特定配置
│   ├── dev/                   # 开发环境配置
│   ├── test/                  # 测试环境配置
│   └── prod/                  # 生产环境配置
├── k8s/                       # Kubernetes 部署模板
├── makefiles/                 # Makefile 模块化配置
├── services/                  # 微服务源代码
│   ├── go-service/            # Go 服务示例
│   └── python-service/        # Python 服务示例
└── terraform-infrastructure/  # Terraform 基础设施代码
```

## 快速开始

### 1. 部署基础设施

初始化并部署 AWS 基础设施（EKS 集群、ECR 仓库等）：

```bash
# 初始化 Terraform
make tf-init

# 部署开发环境
make tf-apply-dev

# 或者部署测试/生产环境
# make tf-apply-test
# make tf-apply-prod
```

### 2. 构建并推送服务镜像

```bash
# 登录 ECR
make login-ecr

# 构建并推送所有服务镜像
make build-all
make push-all

# 或者单独构建和推送特定服务
# make push-python-service
# make push-go-service
```

### 3. 部署服务到 Kubernetes

```bash
# 部署到开发环境
make deploy-dev

# 或者部署到测试/生产环境
# make deploy-test
# make deploy-prod
```

## 多环境配置

项目支持多环境部署，环境配置存储在 `envs/` 目录下：

- `envs/dev/` - 开发环境配置
- `envs/test/` - 测试环境配置
- `envs/prod/` - 生产环境配置

每个环境目录包含：

- `.env` - 环境通用配置
- `terraform.tfvars` - Terraform 变量
- 各服务的环境变量文件 (如 `go-service.env`)

## CI/CD 流程

项目使用 GitHub Actions 实现 CI/CD 自动化，工作流定义在 `.github/workflows/eks-deploy.yaml` 中：

- 推送到 `main` 分支自动触发部署
- 支持手动触发并选择目标环境
- 自动构建和推送 Docker 镜像
- 自动部署到指定的 EKS 集群

## 高级使用指南

详细文档位于 `docs/` 目录：

- [Makefile 说明](docs/Makefile说明.md)
- [如何添加新应用到集群](docs/如何添加新应用到集群.md)
- [如何从集群中移除应用](docs/如何从集群中移除应用.md)
- [如何绑定自定义域名](docs/如何绑定自定义域名.md)
- [多环境部署隔离策略建议](docs/多环境部署隔离策略建议.md)

## 注意事项

- 确保已安装 AWS CLI、kubectl、Docker 和 Terraform
- 确保已配置 AWS 凭证
- 使用前请仔细阅读 `docs/` 目录下的文档
- 生产环境部署前请确保已经在测试环境验证
