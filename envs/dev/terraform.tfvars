aws_region            = "ap-southeast-1"
project_name          = "sentienfi-test"
cluster_name          = "sentienfi-test-cluster"
vpc_cidr_block        = "10.2.0.0/16"
service_names         = ["go-service","python-service"]
instance_types        = ["t3.medium"]
disk_size             = 20
ami_type              = "AL2023_x86_64_STANDARD"
eks_version           = "1.33"
endpoint_private_access = false
endpoint_public_access  = true
enable_dns_support      = true
enable_dns_hostnames    = true
public_subnet_count     = 3
private_subnet_count    = 3
vpc_tags = {
  Terraform   = "true"
  Environment = "test"
}
github_repo             = "aurion-group/*"
eso_namespace           = "external-secrets"
eso_service_account_name = "external-secrets-sa"
ssm_prefix              = "sentienfi-test"
cluster_secret_store_name = "aws-ssm-store"
