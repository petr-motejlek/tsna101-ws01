variable "aws_region" {
  description = "AWS region to deploy all resources into."
  type        = string
  default     = "eu-west-1"
}

variable "project" {
  description = "Short project/workshop identifier used in Name tags and resource names."
  type        = string
  default     = "tsna101-ws01"
}

variable "vpc1_cidr" {
  description = "CIDR block for VPC 1 (frontend / ALB network)."
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc2_cidr" {
  description = "CIDR block for VPC 2 (backend / ECS network)."
  type        = string
  default     = "10.1.0.0/16"
}

variable "ecs_desired_count" {
  description = "Desired number of ECS Fargate tasks running the echo-server."
  type        = number
  default     = 1
}

variable "ecs_image" {
  description = "Container image for the ECS task."
  type        = string
  default     = "ealen/echo-server:latest"
}
