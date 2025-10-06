output "db_subnet_group_id" {
  value = aws_db_subnet_group.db_subnet_group.id
}

output "rds_security_group_id" {
    value = aws_security_group.rds_sg.id
}

output "glue_security_group_id" {
  value = aws_security_group.glue_sg.id
}

output "lambda_security_group_id" {
  value = aws_security_group.lambda_sg.id
}

output "quicksight_security_group_id" {
  description = "Security group ID for QuickSight VPC connection"
  value       = aws_security_group.quicksight_sg.id
}

output "private_subnet_a_id" {
  description = "Private subnet A id"
  value       = aws_subnet.private_subnet_a.id
}

output "subnet_a_availability_zone" {
  description = "Availability zone for subnet A"
  value       = aws_subnet.private_subnet_a.availability_zone
}

output "private_subnet_b_id" {
  description = "Private subnet B id"
  value       = aws_subnet.private_subnet_b.id
}

output "rds_public_subnet_a_id" {
  description = "RDS Public subnet A id"
  value       = aws_subnet.rds_public_subnet_a.id
}

output "rds_public_subnet_b_id" {
  description = "RDS Public subnet B id"
  value       = aws_subnet.rds_public_subnet_b.id
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main_vpc.id
}