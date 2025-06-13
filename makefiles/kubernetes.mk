# Kubernetes deployment operations

.PHONY: deploy-dev deploy-test deploy-prod deploy destroy-dev destroy-test destroy-prod destroy

# 通用部署函数
define deploy_env
	@echo "Updating kubeconfig for $(1) environment..."
	aws eks update-kubeconfig --name $${CLUSTER_NAME} --region $${AWS_REGION} && \
	export AWS_ACCOUNT_ID=$${AWS_ACCOUNT_ID} && \
	export AWS_REGION=$${AWS_REGION} && \
	export NAMESPACE=$${NAMESPACE} && \
	export ALB_GROUP_NAME=$${ALB_GROUP_NAME} && \
	export DOMAIN_NAME=$${DOMAIN_NAME} && \
	kubectl config use-context arn:aws:eks:$${AWS_REGION}:$${AWS_ACCOUNT_ID}:cluster/$${CLUSTER_NAME} && \
	echo "Deploying namespace first..." && \
	envsubst < k8s/00-namespace-template.yaml | kubectl apply --validate=false -f - && \
	echo "Deploying all services and their HPAs dynamically..." && \
	for service in $(SERVICES); do \
		if [ -f "envs/$(1)/$$service.env" ]; then \
			echo "Deploying $$service..."; \
			set -a && source "envs/$(1)/.env" && source "envs/$(1)/$$service.env" && export SERVICE_NAME=$$service && \
			envsubst < k8s/01-service-deployment-template.yaml | kubectl apply --validate=false -f -; \
			set -a && source "envs/$(1)/.env" && source "envs/$(1)/$$service.env" && export SERVICE_NAME=$$service && \
			envsubst < k8s/02-hpa-template.yaml | kubectl apply --validate=false -f -; \
			echo "Deploying ingress for $$service..."; \
			set -a && source "envs/$(1)/.env" && source "envs/$(1)/$$service.env" && \
			export SERVICE_NAME=$$service && \
			export SERVICE_PATH=`grep "^SERVICE_PATH=" "envs/$(1)/$$service.env" | cut -d'=' -f2 || echo "/$$service"` && \
			envsubst < k8s/03-ingress-template.yaml | kubectl apply --validate=false -f -; \
		else \
			echo "Warning: No config file found for $$service, skipping..."; \
		fi; \
	done && \
	echo "Restarting all service deployments..." && \
	for service in $(SERVICES); do \
		if kubectl get deployment $$service -n $(NAMESPACE) >/dev/null 2>&1; then \
			kubectl rollout restart deployment/$$service -n $(NAMESPACE); \
		fi; \
	done
endef

# 环境特定部署
deploy-dev:
	$(MAKE) ENV=dev _deploy

deploy-test:
	$(MAKE) ENV=test _deploy

deploy-prod:
	$(MAKE) ENV=prod _deploy

deploy:
	$(call deploy_env,$(ENV))

# 内部部署目标
_deploy:
	$(call deploy_env,$(ENV))

# 环境特定的销毁
# 通用销毁函数
# 验证环境配置文件
define validate_env_file
	@if [ ! -f "envs/$(1)/.env" ]; then \
		echo "Error: Environment file envs/$(1)/.env not found"; \
		exit 1; \
	fi
endef

# 获取环境配置值的通用函数
define get_env_value
$(shell if [ -f "envs/$(1)/.env" ]; then grep '^$(2)=' envs/$(1)/.env | cut -d'=' -f2; fi)
endef

# 改进的销毁函数
define destroy_env
	$(call validate_env_file,$(1))
	@NAMESPACE_TO_DELETE="$(call get_env_value,$(1),NAMESPACE)"; \
	if [ -z "$$NAMESPACE_TO_DELETE" ]; then \
		echo "Error: NAMESPACE not defined in envs/$(1)/.env"; \
		exit 1; \
	fi; \
	echo "Destroying $(1) environment (namespace: $$NAMESPACE_TO_DELETE)..."; \
	if [ "$(1)" = "prod" ]; then \
		echo "WARNING: This will destroy PRODUCTION environment!"; \
		read -p "Are you sure? Type 'yes' to continue: " confirm && [ "$$confirm" = "yes" ] || exit 1; \
	fi; \
	echo "Deleting namespace: $$NAMESPACE_TO_DELETE"; \
	kubectl delete namespace $$NAMESPACE_TO_DELETE --ignore-not-found=true && \
	echo "✓ Namespace $$NAMESPACE_TO_DELETE deleted successfully" || \
	echo "✗ Failed to delete namespace $$NAMESPACE_TO_DELETE"
endef

# 环境特定的销毁
destroy-dev:
	$(call destroy_env,dev)

destroy-test:
	$(call destroy_env,test)

destroy-prod:
	$(call destroy_env,prod)

# 通用销毁（使用当前环境变量）
destroy:
	@echo "Destroying namespace: $(NAMESPACE)"
	kubectl delete namespace $(NAMESPACE) --ignore-not-found=true

# 检查环境状态
status-%:
	$(call validate_env_file,$*)
	@NAMESPACE_TO_CHECK="$(call get_env_value,$*,NAMESPACE)"; \
	echo "Checking status for $* environment (namespace: $$NAMESPACE_TO_CHECK)"; \
	if kubectl get namespace $$NAMESPACE_TO_CHECK >/dev/null 2>&1; then \
		echo "✓ Namespace exists"; \
		echo "Pods in namespace:"; \
		kubectl get pods -n $$NAMESPACE_TO_CHECK; \
		echo "Services in namespace:"; \
		kubectl get services -n $$NAMESPACE_TO_CHECK; \
	else \
		echo "✗ Namespace does not exist"; \
	fi

# 通用状态检查
status:
	@echo "Checking status for environment: $(ENV)"
	@$(MAKE) status-$(ENV)

# 干运行销毁（仅显示将要执行的操作）
dry-run-destroy-%:
	$(call validate_env_file,$*)
	@NAMESPACE_TO_DELETE="$(call get_env_value,$*,NAMESPACE)"; \
	echo "[DRY RUN] Would destroy $* environment (namespace: $$NAMESPACE_TO_DELETE)"; \
	echo "[DRY RUN] Command that would be executed:"; \
	echo "kubectl delete namespace $$NAMESPACE_TO_DELETE --ignore-not-found=true"


run-metrics:
	@echo "Checking Metrics Server status..."
	@kubectl get deployment metrics-server -n kube-system
	@echo "Testing Metrics API..."
	@kubectl top nodes
	@kubectl top pods -A