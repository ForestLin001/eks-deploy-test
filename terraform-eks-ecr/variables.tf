/*
  This file declares input variables used throughout 
  the Terraform configuration.
*/
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "your-region"
}

variable "project_name" {
  description = "Prefix for resource naming"
  type        = string
  default     = "your-project-name"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "your-cluster-name"
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block"
  type        = string
  default     = "your-cidr-block"
}

variable "service_names" {
  description = "List of service names for ECR repositories"
  type        = list(string)
  default     = ["your-service1", "your-service2"]
}

variable "instance_types" {
  description = "EC2 instance types for EKS worker nodes"
  type        = list(string)
  default     = ["your-instance-type1", "your-instance-type2"]
}

variable "disk_size" {
  description = "Disk size for EKS worker nodes (GiB)"
  type        = number
  default     = 20
}

variable "ami_type" {
  description = "AMI type for EKS worker nodes"
  type        = string
  default     = "your-ami-type"
}

variable "eks_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.33"
}

variable "endpoint_private_access" {
  description = "Enable private access to EKS endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public access to EKS endpoint"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in VPC"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in VPC"
  type        = bool
  default     = true
}

variable "public_subnet_count" {
  description = "Number of public subnets"
  type        = number
  default     = 2
}

variable "private_subnet_count" {
  description = "Number of private subnets"
  type        = number
  default     = 2
}

variable "vpc_tags" {
  description = "Tags to apply to the VPC and related resources"
  type        = map(string)
  default     = {
    Terraform   = "true"
    Environment = "your-environment"
  }
}

variable "github_repo" {
  description = "GitHub repository in format: owner/repo"
  type        = string
  default     = "aurion-group/*"
}