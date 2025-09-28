// ...existing code...
variable "project_name" {
  type        = string
  description = "Project name prefix"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  sensitive   = true
}

variable "aws_account_id" {
  type        = string
  description = "AWS account id (used for QuickSight resource ARN)"
  sensitive   = true
}

variable "scripts_bucket" {
  type        = string
  description = "S3 bucket name to upload Glue scripts into"
}

variable "data_bucket" {
  type        = string
  description = "S3 bucket name for data storage"
}

# variable "quicksight_account_id" {
#   type        = string
#   description = "QuickSight account id"
#   default     = ""
# }

# variable "quicksight_data_set_id" {
#   type        = string
#   description = "QuickSight dataset id to trigger ingestion for"
#   default     = ""
# }

variable "glue_max_capacity" {
  type        = number
  description = "Glue max capacity (DPU equivalent or number for worker-based)"
  default     = 2
}

variable "glue_worker_type" {
  type        = string
  description = "Glue worker type (G.1X, G.2X)"
  default     = "G.1X"
}

variable "db_host" {
  type        = string
  description = "Database host"
  sensitive   = true
}

variable "db_port" {
  type        = number
  description = "Database port"
  sensitive   = true
}

variable "db_name" {
  type        = string
  description = "Database name"
  sensitive   = true
}

variable "vpc_subnet_id" {
  type        = string
  description = "VPC subnet ID for Glue job"
}

variable "glue_security_group_id" {
  type        = string
  description = "Security group ID for Glue job"
}

variable "db_secret_id" {
  type        = string
  description = "Secrets Manager secret id for DB credentials"
  sensitive   = true
}

variable "availability_zone" {
  type        = string
  description = "Availability zone for Glue job"
}

variable "db_secret_arn" {
  type        = string
  description = "ARN of the database secrets in Secrets Manager"
}

variable "db_secret_name" {
  type        = string
  description = "Name of the database secret"
}

variable "private_subnet_b_id" {
  type        = string
  description = "Private subnet B ID for Lambda"
}

variable "lambda_security_group_id" {
  type        = string
  description = "Security group ID for Lambda"
}
