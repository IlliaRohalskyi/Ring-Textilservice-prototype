resource "aws_secretsmanager_secret" "db_secret" {
  name        = "${var.db_name}-credentials"
  description = "Credentials for ${var.db_name}"
  tags = {
    Project = var.db_name
  }
}

resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    USERNAME = var.db_username
    password = var.db_password
    host     = var.db_host
    port     = var.db_port
    dbname   = var.db_name
  })
}
