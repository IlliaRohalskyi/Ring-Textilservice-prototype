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
