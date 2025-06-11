# Makefile for eks-deploy-test

AWS_ACCOUNT_ID := 440744252731
AWS_REGION := ap-southeast-1
PYTHON_REPO := $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/python-service
GO_REPO := $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/go-service
CLUSTER_NAME := sentienfi-test-cluster
TFVARS ?= dev.tfvars

.PHONY: tf-init tf-plan tf-apply tf-destroy

# 初始化
tf-init:
	cd terraform-eks-ecr && terraform init

# 预览
tf-plan:
	cd terraform-eks-ecr && terraform plan -var-file=$(TFVARS)

# 应用
tf-apply:
	cd terraform-eks-ecr && terraform apply -var-file=$(TFVARS) -auto-approve

# 销毁
tf-destroy:
	cd terraform-eks-ecr && terraform destroy -var-file=$(TFVARS) -auto-approve

build-python:
	docker build --platform=linux/amd64 -t python-service ./python-service

build-go:
	docker build --platform=linux/amd64 -t go-service ./go-service

push-python: build-python
	docker tag python-service:latest $(PYTHON_REPO):latest
	docker push $(PYTHON_REPO):latest

push-go: build-go
	docker tag go-service:latest $(GO_REPO):latest
	docker push $(GO_REPO):latest

login-ecr:
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com

deploy:
	aws eks update-kubeconfig --name $(CLUSTER_NAME) --region $(AWS_REGION) && \
	export AWS_ACCOUNT_ID=$(AWS_ACCOUNT_ID) && \
	export AWS_REGION=$(AWS_REGION) && \
	kubectl config use-context arn:aws:eks:$(AWS_REGION):$(AWS_ACCOUNT_ID):cluster/$(CLUSTER_NAME) && \
	envsubst < k8s/python-deployment.yaml | kubectl apply --validate=false -f - && \
	envsubst < k8s/go-deployment.yaml | kubectl apply --validate=false -f - && \
	kubectl apply --validate=false -f k8s/00-namespace.yaml -f k8s/ingress.yaml && \
	kubectl rollout restart deployment/python-service deployment/go-service -n digitalaurion-test

destroy:
	kubectl delete -f k8s/