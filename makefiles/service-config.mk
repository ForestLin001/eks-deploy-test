# Service configuration management

.PHONY: generate-service-config generate-all-service-configs list-service-configs

# Generate service configuration with environment-specific defaults
# Usage: make generate-service-config SERVICE=go-service PORT=8080 [SERVICE_PATH=/go] ENV=dev
generate-service-config:
	@echo "Debug: SERVICE=$(SERVICE), PORT=$(PORT), SERVICE_PATH=$(SERVICE_PATH), ENV=$(ENV)"
	@if [ -z "$(SERVICE)" ] || [ -z "$(PORT)" ]; then \
		echo "Usage: make generate-service-config SERVICE=<name> PORT=<port> [SERVICE_PATH=<path>] ENV=<env>"; \
		echo "Example: make generate-service-config SERVICE=go-service PORT=8080 SERVICE_PATH=/go ENV=dev"; \
		exit 1; \
	fi
	@mkdir -p envs/$(ENV)
	@echo "SERVICE_NAME=$(SERVICE)" > envs/$(ENV)/$(SERVICE).env
	@echo "CONTAINER_PORT=$(PORT)" >> envs/$(ENV)/$(SERVICE).env
	@if [ -n "$(SERVICE_PATH)" ]; then \
		echo "SERVICE_PATH=$(SERVICE_PATH)" >> envs/$(ENV)/$(SERVICE).env; \
	else \
		echo "SERVICE_PATH=/$(SERVICE)" >> envs/$(ENV)/$(SERVICE).env; \
	fi
	@echo "# Resource and HPA configuration" >> envs/$(ENV)/$(SERVICE).env
	@if [ "$(ENV)" = "dev" ]; then \
		echo "REPLICAS=1" >> envs/$(ENV)/$(SERVICE).env; \
		echo "CPU_REQUEST=100m" >> envs/$(ENV)/$(SERVICE).env; \
		echo "MEMORY_REQUEST=128Mi" >> envs/$(ENV)/$(SERVICE).env; \
		echo "CPU_LIMIT=500m" >> envs/$(ENV)/$(SERVICE).env; \
		echo "MEMORY_LIMIT=512Mi" >> envs/$(ENV)/$(SERVICE).env; \
		echo "MIN_REPLICAS=1" >> envs/$(ENV)/$(SERVICE).env; \
		echo "MAX_REPLICAS=3" >> envs/$(ENV)/$(SERVICE).env; \
		echo "CPU_UTILIZATION=80" >> envs/$(ENV)/$(SERVICE).env; \
		echo "MEMORY_UTILIZATION=85" >> envs/$(ENV)/$(SERVICE).env; \
	elif [ "$(ENV)" = "test" ]; then \
		echo "REPLICAS=2" >> envs/$(ENV)/$(SERVICE).env; \
		echo "CPU_REQUEST=150m" >> envs/$(ENV)/$(SERVICE).env; \
		echo "MEMORY_REQUEST=192Mi" >> envs/$(ENV)/$(SERVICE).env; \
		echo "CPU_LIMIT=750m" >> envs/$(ENV)/$(SERVICE).env; \
		echo "MEMORY_LIMIT=768Mi" >> envs/$(ENV)/$(SERVICE).env; \
		echo "MIN_REPLICAS=1" >> envs/$(ENV)/$(SERVICE).env; \
		echo "MAX_REPLICAS=5" >> envs/$(ENV)/$(SERVICE).env; \
		echo "CPU_UTILIZATION=75" >> envs/$(ENV)/$(SERVICE).env; \
		echo "MEMORY_UTILIZATION=80" >> envs/$(ENV)/$(SERVICE).env; \
	elif [ "$(ENV)" = "prod" ]; then \
		echo "REPLICAS=3" >> envs/$(ENV)/$(SERVICE).env; \
		echo "CPU_REQUEST=200m" >> envs/$(ENV)/$(SERVICE).env; \
		echo "MEMORY_REQUEST=256Mi" >> envs/$(ENV)/$(SERVICE).env; \
		echo "CPU_LIMIT=1000m" >> envs/$(ENV)/$(SERVICE).env; \
		echo "MEMORY_LIMIT=1Gi" >> envs/$(ENV)/$(SERVICE).env; \
		echo "MIN_REPLICAS=3" >> envs/$(ENV)/$(SERVICE).env; \
		echo "MAX_REPLICAS=10" >> envs/$(ENV)/$(SERVICE).env; \
		echo "CPU_UTILIZATION=60" >> envs/$(ENV)/$(SERVICE).env; \
		echo "MEMORY_UTILIZATION=70" >> envs/$(ENV)/$(SERVICE).env; \
	else \
		echo "REPLICAS=1" >> envs/$(ENV)/$(SERVICE).env; \
		echo "CPU_REQUEST=100m" >> envs/$(ENV)/$(SERVICE).env; \
		echo "MEMORY_REQUEST=128Mi" >> envs/$(ENV)/$(SERVICE).env; \
		echo "CPU_LIMIT=500m" >> envs/$(ENV)/$(SERVICE).env; \
		echo "MEMORY_LIMIT=512Mi" >> envs/$(ENV)/$(SERVICE).env; \
		echo "MIN_REPLICAS=1" >> envs/$(ENV)/$(SERVICE).env; \
		echo "MAX_REPLICAS=3" >> envs/$(ENV)/$(SERVICE).env; \
		echo "CPU_UTILIZATION=70" >> envs/$(ENV)/$(SERVICE).env; \
		echo "MEMORY_UTILIZATION=80" >> envs/$(ENV)/$(SERVICE).env; \
	fi
	@echo "Generated envs/$(ENV)/$(SERVICE).env with $(ENV) environment defaults"

# Generate service configs for all discovered services
generate-all-service-configs:
	@echo "Generating service configs for all services..."
	@for service in $(SERVICES); do \
		if [ -f "envs/$(ENV)/$$service.env" ]; then \
			port=$$(grep "^CONTAINER_PORT=" "envs/$(ENV)/$$service.env" | cut -d'=' -f2); \
			service_path=$$(grep "^SERVICE_PATH=" "envs/$(ENV)/$$service.env" | cut -d'=' -f2); \
			if [ -n "$$port" ]; then \
				echo "Using existing port $$port for $$service"; \
				if [ -n "$$service_path" ]; then \
					echo "Using existing path $$service_path for $$service"; \
					$(MAKE) generate-service-config SERVICE=$$service PORT=$$port SERVICE_PATH=$$service_path ENV=$(ENV); \
				else \
					echo "No path found for $$service, using default /$$service"; \
					$(MAKE) generate-service-config SERVICE=$$service PORT=$$port ENV=$(ENV); \
				fi; \
			else \
				echo "No port found for $$service, using default 8080"; \
				$(MAKE) generate-service-config SERVICE=$$service PORT=8080 ENV=$(ENV); \
			fi; \
		else \
			echo "No existing config for $$service, using default port 8080"; \
			$(MAKE) generate-service-config SERVICE=$$service PORT=8080 ENV=$(ENV); \
		fi; \
	done

# List all service configuration files
list-service-configs:
	@echo "Service configuration files:"
	@find envs -name "*.env" -not -name "config.env" | sort


# Update service_names in terraform.tfvars while keeping other lines unchanged
update-terraform-service-names:
	@echo "Updating service_names in terraform.tfvars for $(ENV) environment..."
	@if [ ! -f "envs/$(ENV)/terraform.tfvars" ]; then \
		echo "Error: envs/$(ENV)/terraform.tfvars not found"; \
		exit 1; \
	fi
	@# Auto-discover services from services/ directory
	@services=$$(find services -maxdepth 1 -type d ! -name services | sed 's|services/||' | sort); \
	service_list=$$(echo "$$services" | sed 's/^/\"/;s/$$/\"/' | tr '\n' ',' | sed 's/,$$//'); \
	echo "Discovered services: $$services"; \
	echo "Updating service_names = [$$service_list]"; \
	sed -i.bak "s/^service_names.*$$/service_names         = [$$service_list]/" envs/$(ENV)/terraform.tfvars
	@echo "Updated envs/$(ENV)/terraform.tfvars - backup saved as .bak"

# Update service_names for all environments
update-all-terraform-service-names:
	@echo "Updating service_names for all environments..."
	@for env in dev test prod; do \
		if [ -f "envs/$$env/terraform.tfvars" ]; then \
			$(MAKE) update-terraform-service-names ENV=$$env; \
		else \
			echo "Skipping $$env - terraform.tfvars not found"; \
		fi; \
	done
