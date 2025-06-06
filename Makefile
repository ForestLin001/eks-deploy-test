# Makefile for eks-deploy-test

AWS_ACCOUNT_ID := 440744252731
REGION := ap-southeast-1
PYTHON_REPO := $(AWS_ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/python-service
GO_REPO := $(AWS_ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/go-service

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