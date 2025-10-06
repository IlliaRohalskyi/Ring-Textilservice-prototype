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

# QuickSight Infrastructure Outputs
output "quicksight_vpc_role_arn" {
  description = "ARN of the IAM role for QuickSight VPC access"
  value       = module.quicksight.quicksight_vpc_role_arn
}

output "quicksight_vpc_role_name" {
  description = "Name of the IAM role for QuickSight VPC access"
  value       = module.quicksight.quicksight_vpc_role_name
}

output "quicksight_security_group_id" {
  description = "Security group ID for QuickSight VPC connection"
  value       = module.networking.quicksight_security_group_id
}

output "quicksight_db_secret_name" {
  description = "Name of the Secrets Manager secret for QuickSight database credentials"
  value       = module.quicksight.quicksight_db_secret_name
}

output "quicksight_subnet_ids" {
  description = "Subnet IDs for QuickSight VPC connection (private subnets)"
  value       = [module.networking.private_subnet_a_id, module.networking.private_subnet_b_id]
}

output "vpc_id" {
  description = "VPC ID for QuickSight VPC connection"
  value       = module.networking.vpc_id
}

output "quicksight_connection_info" {
  description = "Database connection information for QuickSight setup"
  value       = module.quicksight.database_connection_info
  sensitive   = true
}