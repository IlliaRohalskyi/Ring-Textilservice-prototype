output data_bucket {
  description = "Name of the data S3 bucket"
  value       = aws_s3_bucket.data_bucket.bucket
}

output "scripts_bucket" {
  description = "Name of the scripts S3 bucket"
  value       = aws_s3_bucket.scripts_bucket.bucket
}

output "db_host" {
  value = aws_db_instance.project_rds.address
  description = "The hostname of the RDS database endpoint"
  sensitive = true
}

output "db_port" {
  value = aws_db_instance.project_rds.port
  description = "The port number the RDS database listens on"
  sensitive = true
}

output "db_name" {
  value = aws_db_instance.project_rds.db_name
  description = "The database name"
  sensitive = true
}