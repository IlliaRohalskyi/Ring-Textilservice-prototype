output "db_secret_id" {
  description = "Secrets Manager secret id for DB credentials"
  value       = aws_secretsmanager_secret.db_secret.id
  sensitive   = true
}