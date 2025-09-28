resource "aws_secretsmanager_secret" "db_secret" {
  name                      = "${var.db_name}-credentials"
  description               = "Credentials for ${var.db_name}"
  recovery_window_in_days   = 0   # Immediate deletion, no recovery window
  tags = {
    Project = var.db_name
  }
}

resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = var.db_host
    port     = var.db_port
    dbname   = var.db_name
  })
}
