output "db_subnet_group_id" {
  value = aws_db_subnet_group.db_subnet_group.id
}

output "rds_security_group_id" {
    value = aws_security_group.rds_sg.id
}

output "glue_security_group_id" {
  value = aws_security_group.glue_sg.id
}

output "private_subnet_a_id" {
  description = "Private subnet A id"
  value       = aws_subnet.private_subnet_a.id
}

output "subnet_a_availability_zone" {
  description = "Availability zone for subnet A"
  value       = aws_subnet.private_subnet_a.availability_zone
}

output "rds_public_subnet_a_id" {
  description = "RDS Public subnet A id"
  value       = aws_subnet.rds_public_subnet_a.id
}

output "rds_public_subnet_b_id" {
  description = "RDS Public subnet B id"
  value       = aws_subnet.rds_public_subnet_b.id
}