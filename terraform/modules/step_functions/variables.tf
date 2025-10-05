variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "glue_job_name" {
  description = "Name of the Glue job to execute"
  type        = string
}

variable "upsert_lambda_arn" {
  description = "ARN of the upsert Lambda function"
  type        = string
}
