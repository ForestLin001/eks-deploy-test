/*
  This file declares input variables used throughout 
  the Terraform configuration.
*/
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Prefix for resource naming"
  default     = "sentienfi-test"
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.2.0.0/16"
}

variable "service_names" {
  description = "List of service names for ECR repositories"
  type        = list(string)
  default     = ["python-service", "go-service"]
}

variable "ec2_ssh_key" {
  description = "EC2 SSH key pair name for EKS worker nodes"
  type        = string
  default     = "your-key-name"
}

variable "instance_types" {
  description = "EC2 instance types for EKS worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "disk_size" {
  description = "Disk size for EKS worker nodes (GiB)"
  type        = number
  default     = 20
}

variable "ami_type" {
  description = "AMI type for EKS worker nodes"
  type        = string
  default     = "AL2_x86_64"
}