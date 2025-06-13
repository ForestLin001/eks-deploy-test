# 自动发现 services 目录下的所有服务
SERVICES := $(shell find services -maxdepth 1 -type d -not -path services | sed 's|services/||')

# 动态生成 ECR 仓库地址
define get_ecr_repo
$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(1)
endef

.PHONY: $(addprefix build-,$(SERVICES)) $(addprefix push-,$(SERVICES)) login-ecr build-all push-all list-services

# 通用构建规则
define build_service_template
build-$(1):
	docker build --platform=linux/amd64 -t $(1) ./services/$(1)
endef

# 通用推送规则
define push_service_template
push-$(1): build-$(1)
	docker tag $(1):latest $(call get_ecr_repo,$(1)):latest
	docker push $(call get_ecr_repo,$(1)):latest
endef

# 为每个服务生成构建和推送规则
$(foreach service,$(SERVICES),$(eval $(call build_service_template,$(service))))
$(foreach service,$(SERVICES),$(eval $(call push_service_template,$(service))))

# ECR 登录
login-ecr:
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com

# 批量操作
build-all: $(addprefix build-,$(SERVICES))

push-all: $(addprefix push-,$(SERVICES))

# 列出所有发现的服务
list-services:
	@echo "Discovered services:"
	@echo $(SERVICES)

# 帮助信息
help-docker:
	@echo "Docker targets:"
	@echo "  build-<service>  - Build specific service"
	@echo "  push-<service>   - Push specific service to ECR"
	@echo "  build-all        - Build all services"
	@echo "  push-all         - Push all services to ECR"
	@echo "  login-ecr        - Login to ECR"
	@echo "  list-services    - List all discovered services"
	@echo ""
	@echo "Available services: $(SERVICES)"