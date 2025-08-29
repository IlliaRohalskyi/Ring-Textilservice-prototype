output "db_subnet_group_id" {
  value = aws_db_subnet_group.db_subnet_group.id
}

output "rds_security_group_id" {
    value = aws_security_group.rds_sg.id
}