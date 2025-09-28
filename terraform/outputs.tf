output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.storage.db_host
  sensitive   = true
}

output "rds_db_name" {
  description = "RDS database name"
  value       = module.storage.db_name
  sensitive   = true
}

output "rds_port" {
  description = "RDS port"
  value       = module.storage.db_port
  sensitive   = true
}

output "lambda_function_name" {
  description = "Name of the Lambda function for schema deployment"
  value       = module.compute.deploy_schema_lambda_name
}