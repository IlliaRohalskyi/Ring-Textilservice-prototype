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

variable "data_db_username" {
  description = "The username for the database"
  type        = string
  sensitive   = true
}

variable "data_db_password" {
  description = "The password for the database"
  type        = string
  sensitive   = true
}

variable "data_instance_class" {
  description = "The instance class for the database"
  type        = string
  default     = "db.t3.micro"
}

variable "ip_address" {
  description = "The IP address to allow access"
  type        = string
  sensitive   = true
}