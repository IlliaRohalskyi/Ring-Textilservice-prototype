// ...existing code...
variable "project_name" {
  description = "Name of the project - used for resource naming"
  type        = string
}

variable "data_instance_class" {
  description = "Instance class for RDS"
  type        = string
}

variable "db_subnet_group_id" {
  description = "ID of the DB subnet group"
  type        = string
}

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs"
  type        = list(string)
}

variable "data_db_username" {
  description = "Username for the Data database"
  type        = string
  sensitive   = true
}

variable "data_db_password" {
  description = "Password for the Data database"
  type        = string
  sensitive   = true
}