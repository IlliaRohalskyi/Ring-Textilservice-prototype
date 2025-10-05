output "glue_job_name" {
  description = "Name of the Glue job created in the compute module"
  value       = aws_glue_job.data_processing_job.name
}

output "deploy_schema_lambda_arn" {
  description = "ARN of the deploy schema Lambda function"
  value       = aws_lambda_function.deploy_schema.arn
}

output "deploy_schema_lambda_name" {
  description = "Name of the deploy schema Lambda function"
  value       = aws_lambda_function.deploy_schema.function_name
}

output "psycopg2_layer_arn" {
  description = "ARN of the psycopg2 Lambda layer"
  value       = aws_lambda_layer_version.psycopg2_layer.arn
}

output "upsert_lambda_arn" {
  description = "ARN of the upsert Lambda function"
  value       = aws_lambda_function.upsert_data.arn
}

output "upsert_lambda_name" {
  description = "Name of the upsert Lambda function"
  value       = aws_lambda_function.upsert_data.function_name
}