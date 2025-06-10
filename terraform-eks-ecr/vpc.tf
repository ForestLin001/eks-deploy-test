/*
  This file provisions the Virtual Private Cloud (VPC) and related networking resources using the official terraform-aws-vpc module.
*/
data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  name = var.project_name
  cidr = var.vpc_cidr_block

  private_subnet_tags = { "kubernetes.io/role/internal-elb" = 1 }
  public_subnet_tags  = { "kubernetes.io/role/elb" = 1 }

  azs             = slice(data.aws_availability_zones.available.names, 0, max(var.public_subnet_count, var.private_subnet_count))
  private_subnets = [for i in range(var.private_subnet_count) : cidrsubnet(var.vpc_cidr_block, 8, i)]
  public_subnets  = [for i in range(var.public_subnet_count) : cidrsubnet(var.vpc_cidr_block, 8, 100 + i)]
  private_subnet_names = [for i in range(var.private_subnet_count) : "${var.project_name}-private-${i}"]
  public_subnet_names  = [for i in range(var.public_subnet_count) : "${var.project_name}-public-${i}"]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = var.vpc_tags
}