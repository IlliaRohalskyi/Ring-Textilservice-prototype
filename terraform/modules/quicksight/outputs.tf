output "quicksight_vpc_role_arn" {
  description = "ARN of the IAM role for QuickSight VPC access"
  value       = aws_iam_role.quicksight_vpc_role.arn
}

output "quicksight_vpc_role_name" {
  description = "Name of the IAM role for QuickSight VPC access"
  value       = aws_iam_role.quicksight_vpc_role.name
}

output "quicksight_db_secret_arn" {
  description = "ARN of the Secrets Manager secret for QuickSight database access"
  value       = aws_secretsmanager_secret.quicksight_db_secret.arn
}

output "quicksight_db_secret_name" {
  description = "Name of the Secrets Manager secret for QuickSight database access"
  value       = aws_secretsmanager_secret.quicksight_db_secret.name
}

output "database_connection_info" {
  description = "Database connection information for manual QuickSight setup"
  value = {
    host     = var.db_host
    port     = var.db_port
    database = var.db_name
    username = var.db_username
  }
  sensitive = true
}


