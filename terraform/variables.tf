variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "ring-textilservice"
}