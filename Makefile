# Makefile for eks-deploy-test

AWS_ACCOUNT_ID := 440744252731
REGION := ap-southeast-1
PYTHON_REPO := $(AWS_ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/python-service
GO_REPO := $(AWS_ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/go-service
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
	docker build -t python-service ./python-service

build-go:
	docker build -t go-service ./go-service

push-python: build-python
	docker tag python-service:latest $(PYTHON_REPO):latest
	docker push $(PYTHON_REPO):latest

push-go: build-go
	docker tag go-service:latest $(GO_REPO):latest
	docker push $(GO_REPO):latest

login-ecr:
	aws ecr get-login-password --region $(REGION) | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com

deploy:
	kubectl apply -f k8s/

destroy:
	kubectl delete -f k8s/