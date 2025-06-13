# 环境变量，默认为开发环境
ENV ?= dev

# 从环境配置文件加载变量
include envs/$(ENV)/.env
export

# 包含子模块
include makefiles/terraform.mk
include makefiles/docker.mk
include makefiles/kubernetes.mk
include makefiles/service-config.mk

# 主要的复合操作
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  Terraform: tf-init, tf-plan, tf-apply, tf-destroy"
	@echo "  Docker: build-all, push-all, build-<service>, push-<service>"
	@echo "  Kubernetes: deploy-dev, deploy-test, deploy-prod"
	@echo "  Utilities: list-services, help-docker"
