/*
  This file defines AWS Elastic Container Registry 
  (ECR) resources for storing Docker images.
*/
# Create ECR repository for Python service
resource "aws_ecr_repository" "service" {
  for_each = toset(var.service_names)
  name     = "${each.value}"
}