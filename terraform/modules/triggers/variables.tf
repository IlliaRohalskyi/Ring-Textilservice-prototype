variable "s3_bucket_name" {
  description = "Name of the S3 bucket to monitor for events"
  type        = string
}

variable "step_function_arn" {
  description = "ARN of the Step Function to trigger when new objects are created"
  type        = string
}

variable "aws_region" {
  description = "AWS region for the resources"
  type        = string
}