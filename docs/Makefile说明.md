# Makefile说明

## 文件结构

- **主 Makefile**：包含公共变量和 include 语句
- **makefiles/terraform.mk**：Terraform 相关操作
- **makefiles/docker.mk**：Docker 构建和推送操作（支持动态服务发现）
- **makefiles/kubernetes.mk**：Kubernetes 部署操作（包含状态检查和干运行功能）
- **makefiles/service-config.mk**：服务配置管理（环境变量文件生成和 Terraform 服务名更新）

## 使用方法

### 1. 查看可用命令

```bash
make help
```

这会显示所有可用的目标，包括：

- **Terraform**: tf-init, tf-plan, tf-apply, tf-destroy, tf-plan-dev, tf-apply-dev, tf-plan-test, tf-apply-test, tf-plan-prod, tf-apply-prod
- **Docker**: build-all, push-all, build-<service>, push-<service>, list-services, login-ecr, help-docker
- **Kubernetes**: deploy-dev, deploy-test, deploy-prod, deploy, destroy-dev, destroy-test, destroy-prod, destroy, status-dev, status-test, status-prod, status, dry-run-destroy-dev, dry-run-destroy-test, dry-run-destroy-prod, run-metrics
- **Service Config**: generate-service-config, generate-all-service-configs, list-service-configs, update-terraform-service-names, update-all-terraform-service-names
- **Utilities**: list-services, help-docker

### 2. 服务管理

#### 查看所有服务

```bash
# 列出所有自动发现的服务
make list-services
```

系统会自动发现 `services/` 目录下的所有子目录作为服务。

#### 查看 Docker 相关帮助

```bash
make help-docker
```

### 3. 服务配置管理

#### 生成单个服务配置

```bash
# 为特定服务和环境生成配置文件
make generate-service-config SERVICE=go-service PORT=8080 ENV=dev
make generate-service-config SERVICE=python-service PORT=8080 ENV=test
make generate-service-config SERVICE=new-service PORT=8080 ENV=prod
```

#### 生成所有服务配置

```bash
# 为所有发现的服务生成配置（需要指定环境）
ENV=dev make generate-all-service-configs
ENV=test make generate-all-service-configs
ENV=prod make generate-all-service-configs
```

#### 查看服务配置文件

```bash
# 列出所有服务配置文件
make list-service-configs
```

#### 更新 Terraform 服务名配置

```bash
# 更新特定环境的 terraform.tfvars 中的 service_names
make update-terraform-service-names ENV=dev

# 更新所有环境的 terraform.tfvars 中的 service_names
make update-all-terraform-service-names
```

#### 环境特定配置

系统会根据不同环境自动生成不同的资源配置：

- **dev 环境**：
  - REPLICAS=1, CPU_REQUEST=100m, MEMORY_REQUEST=128Mi
  - CPU_LIMIT=500m, MEMORY_LIMIT=512Mi
  - MIN_REPLICAS=1, MAX_REPLICAS=3
  - CPU_UTILIZATION=80%, MEMORY_UTILIZATION=85%

- **test 环境**：
  - REPLICAS=2, CPU_REQUEST=150m, MEMORY_REQUEST=192Mi
  - CPU_LIMIT=750m, MEMORY_LIMIT=768Mi
  - MIN_REPLICAS=2, MAX_REPLICAS=5
  - CPU_UTILIZATION=75%, MEMORY_UTILIZATION=80%

- **prod 环境**：
  - REPLICAS=3, CPU_REQUEST=200m, MEMORY_REQUEST=256Mi
  - CPU_LIMIT=1000m, MEMORY_LIMIT=1Gi
  - MIN_REPLICAS=3, MAX_REPLICAS=10
  - CPU_UTILIZATION=60%, MEMORY_UTILIZATION=70%

### 4. Terraform 操作

```bash
# 初始化 Terraform
make tf-init

# 查看计划（使用当前环境的 tfvars）
make tf-plan

# 应用更改
make tf-apply

# 销毁基础设施
make tf-destroy

# 环境特定操作
make tf-plan-dev
make tf-apply-dev
make tf-plan-test
make tf-apply-test
make tf-plan-prod
make tf-apply-prod
```

### 5. Docker 操作

#### 基础操作

```bash
# 登录 ECR
make login-ecr

# 列出所有发现的服务
make list-services
```

#### 构建服务

```bash
# 构建特定服务（动态生成的目标）
make build-python-service
make build-go-service
make build-<任何服务名>

# 构建所有服务
make build-all
```

#### 推送服务

```bash
# 推送特定服务到 ECR
make push-python-service
make push-go-service
make push-<任何服务名>

# 推送所有服务
make push-all
```

### 6. Kubernetes 部署

#### 部署操作

```bash
# 部署到特定环境
make deploy-dev
make deploy-test
make deploy-prod

# 使用环境变量部署
ENV=test make deploy
```

#### 销毁操作

```bash
# 销毁特定环境（安全销毁，从 .env 文件读取配置）
make destroy-dev
make destroy-test
make destroy-prod

# 使用环境变量销毁
ENV=test make destroy
```

#### 状态检查

```bash
# 检查特定环境状态
make status-dev
make status-test
make status-prod

# 使用环境变量检查状态
ENV=test make status
```

#### 干运行销毁（安全预览）

```bash
# 预览销毁操作而不实际执行
make dry-run-destroy-dev
make dry-run-destroy-test
make dry-run-destroy-prod
```

#### 监控指标

```bash
# 检查 Metrics Server 状态并测试 API
make run-metrics
```

### 7. 环境变量控制

```bash
# 默认使用开发环境
make tf-plan  # 等同于 ENV=dev make tf-plan

# 指定环境
ENV=test make tf-plan
ENV=prod make tf-apply
ENV=dev make deploy
```

## 服务管理特性

### 自动服务发现

系统会自动扫描 `services/` 目录下的所有子目录，并为每个服务生成相应的构建和推送目标。

### 动态目标生成

- **构建目标**：`build-<服务名>`
- **推送目标**：`push-<服务名>`
- **ECR 仓库**：自动使用服务名作为 ECR 仓库名

### 服务配置模板化

- **配置文件生成**：`generate-service-config`
- **环境特定配置**：根据环境自动调整资源配置
- **批量生成**：`generate-all-service-configs`
- **Terraform 集成**：自动更新 terraform.tfvars 中的服务名列表

### 安全的环境管理

- **配置文件验证**：销毁操作前验证环境配置文件存在
- **生产环境保护**：生产环境销毁需要用户确认
- **状态检查**：部署前后可检查环境状态
- **干运行模式**：预览销毁操作而不实际执行

### 添加新服务

1. 在 `services/` 目录下创建新的服务目录
2. 添加 `Dockerfile` 和相关代码
3. 生成服务配置文件
4. 更新 Terraform 服务名配置
5. 运行 `make list-services` 确认服务被发现
6. 使用 `make build-<新服务名>` 构建

例如，添加一个名为 `node-service` 的新服务：

```bash
# 创建服务目录
mkdir services/node-service

# 添加 Dockerfile 和代码
# ...

# 生成服务配置
make generate-service-config SERVICE=node-service PORT=8080 ENV=dev
make generate-service-config SERVICE=node-service PORT=8080 ENV=test
make generate-service-config SERVICE=node-service PORT=8080 ENV=prod

# 更新 Terraform 配置
make update-all-terraform-service-names

# 验证服务被发现
make list-services

# 构建新服务
make build-node-service

# 推送新服务
make push-node-service
```

## 完整的工作流程示例

### 首次部署到开发环境

```bash
# 1. 查看所有服务
make list-services

# 2. 生成服务配置（如果还没有）
make generate-all-service-configs ENV=dev

# 3. 更新 Terraform 服务名配置
make update-terraform-service-names ENV=dev

# 4. 初始化 Terraform
make tf-init

# 5. 创建基础设施
make tf-apply-dev

# 6. 登录 ECR
make login-ecr

# 7. 构建并推送所有镜像
make build-all
make push-all

# 8. 部署应用
make deploy-dev

# 9. 检查部署状态
make status-dev
```

### 更新特定服务到测试环境

```bash
# 1. 确保有测试环境配置
make generate-service-config SERVICE=python-service PORT=8080 ENV=test

# 2. 构建特定服务
make build-python-service

# 3. 推送特定服务
make push-python-service

# 4. 重新部署到测试环境
make deploy-test

# 5. 检查部署状态
make status-test
```

### 添加新服务并部署

```bash
# 1. 创建新服务目录和文件
mkdir services/new-service
# 添加 Dockerfile 等文件

# 2. 生成服务配置
make generate-service-config SERVICE=new-service PORT=4000 ENV=dev

# 3. 更新 Terraform 配置
make update-terraform-service-names ENV=dev

# 4. 验证服务被发现
make list-services

# 5. 构建新服务
make build-new-service

# 6. 推送新服务
make push-new-service

# 7. 部署到开发环境
make deploy-dev
```

### 生产环境部署

```bash
# 1. 生成生产环境配置
make generate-all-service-configs ENV=prod

# 2. 更新 Terraform 配置
make update-terraform-service-names ENV=prod

# 3. 先创建生产环境基础设施
make tf-apply-prod

# 4. 构建并推送所有服务
make build-all
make push-all

# 5. 部署应用
make deploy-prod

# 6. 检查部署状态
make status-prod
```

### 安全销毁环境

```bash
# 1. 预览销毁操作（干运行）
make dry-run-destroy-test

# 2. 检查当前状态
make status-test

# 3. 执行销毁（生产环境需要确认）
make destroy-test
```

## 注意事项

1. **自动发现**：系统会自动发现 `services/` 目录下的所有子目录作为服务
2. **变量共享**：所有 `.mk` 文件都可以使用主 Makefile 中定义的变量
3. **环境配置**：通过 `ENV` 变量和 `envs/` 目录实现多环境支持
4. **依赖关系**：某些操作有依赖关系（如需要先 `tf-apply` 再 `deploy`）
5. **ECR 仓库命名**：服务名直接作为 ECR 仓库名，确保 ECR 中有对应的仓库
6. **Dockerfile 要求**：每个服务目录下必须有 `Dockerfile` 文件
7. **配置文件管理**：建议为每个服务在所有环境中都生成配置文件
8. **端口配置**：不同服务需要指定不同的端口号
9. **安全销毁**：销毁操作会从 `.env` 文件读取配置，确保操作的准确性
10. **生产环境保护**：生产环境销毁需要用户输入 'yes' 确认

## 故障排除

### 服务未被发现

```bash
# 检查服务目录结构
ls -la services/

# 验证服务发现
make list-services
```

### 构建失败

```bash
# 检查 Dockerfile 是否存在
ls services/<服务名>/Dockerfile

# 手动测试 Docker 构建
docker build --platform=linux/amd64 -t test ./services/<服务名>
```

### ECR 推送失败

```bash
# 确保已登录 ECR
make login-ecr

# 检查 ECR 仓库是否存在
aws ecr describe-repositories --region ap-southeast-1
```

### 配置文件问题

```bash
# 检查配置文件是否存在
ls envs/<环境名>/<服务名>.env

# 查看配置文件内容
cat envs/<环境名>/<服务名>.env

# 重新生成配置文件
make generate-service-config SERVICE=<服务名> PORT=<端口> ENV=<环境>
```

### 部署失败

```bash
# 检查所有必需的配置文件
make list-service-configs

# 确保服务配置文件存在
make generate-all-service-configs ENV=<环境>

# 检查环境状态
make status-<环境>

# 检查 Kubernetes 资源
kubectl get pods -n <命名空间>
kubectl describe deployment <服务名> -n <命名空间>
```

### 环境配置文件问题

```bash
# 检查环境配置文件是否存在
ls envs/<环境名>/.env

# 查看环境配置文件内容
cat envs/<环境名>/.env

# 预览销毁操作
make dry-run-destroy-<环境名>
```

### Terraform 服务名不同步

```bash
# 检查当前 terraform.tfvars 中的服务名
grep service_names envs/<环境名>/terraform.tfvars

# 更新服务名配置
make update-terraform-service-names ENV=<环境>

# 更新所有环境的服务名配置
make update-all-terraform-service-names
```
