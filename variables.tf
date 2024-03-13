# variables.tf

variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Application Environment, such as dev, prod"
}

variable "aws_profile" {
  type        = string
  default     = "app_deployment_dev"
  description = "AWS profile which is used for the deployment"
}

variable "network_cidr" {
  description = "IP addressing for the network"
}

# number of containers running on the ECS Cluster
variable "app_count" {
  type    = number
  default = 1
}

variable "additional-tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default = {
    application = "xray-poc"
    env         = "development"
  }
}

variable "images_bucket" {
}
