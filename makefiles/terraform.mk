# Terraform operations

.PHONY: tf-init tf-plan tf-apply tf-destroy

tf-init:
	cd terraform-infrastructure && terraform init

tf-plan:
	cd terraform-infrastructure && terraform plan -var-file=../$(TFVARS)

tf-apply:
	cd terraform-infrastructure && terraform apply -var-file=../$(TFVARS) -auto-approve

tf-destroy:
	cd terraform-infrastructure && terraform destroy -var-file=../$(TFVARS) -auto-approve

# 环境特定的 Terraform 操作
tf-plan-dev:
	cd terraform-infrastructure && terraform plan -var-file=../envs/dev/terraform.tfvars

tf-apply-dev:
	cd terraform-infrastructure && terraform apply -var-file=../envs/dev/terraform.tfvars -auto-approve

tf-plan-test:
	cd terraform-infrastructure && terraform plan -var-file=../envs/test/terraform.tfvars

tf-apply-test:
	cd terraform-infrastructure && terraform apply -var-file=../envs/test/terraform.tfvars -auto-approve

tf-plan-prod:
	cd terraform-infrastructure && terraform plan -var-file=../envs/prod/terraform.tfvars

tf-apply-prod:
	cd terraform-infrastructure && terraform apply -var-file=../envs/prod/terraform.tfvars -auto-approve