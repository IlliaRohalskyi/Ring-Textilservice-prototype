output "db_secret_id" {
  description = "Secrets Manager secret id for DB credentials"
  value       = aws_secretsmanager_secret.db_secret.id
  sensitive   = true
}

output "db_secret_name" {
  description = "Secrets Manager secret name for DB credentials"
  value       = aws_secretsmanager_secret.db_secret.name
}

output "db_secret_arn" {
  description = "Secrets Manager secret ARN for DB credentials"
  value       = aws_secretsmanager_secret.db_secret.arn
}