variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "quicksight_security_group_id" {
  description = "Security group ID for QuickSight (from networking module)"
  type        = string
}

variable "db_host" {
  description = "RDS database host"
  type        = string
}

variable "db_port" {
  description = "RDS database port"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "RDS database name"
  type        = string
}

variable "db_username" {
  description = "RDS database username"
  type        = string
}

variable "db_password" {
  description = "RDS database password"
  type        = string
  sensitive   = true
}

variable "db_secret_arn" {
  description = "ARN of the main database secret (from secretsmanager module)"
  type        = string
}