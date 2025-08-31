variable "db_username" {
  description = "The database username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "The database password"
  type        = string
  sensitive   = true
}

variable "db_host" {
  description = "The database host"
  type        = string
  sensitive   = true
}

variable "db_port" {
  description = "The database port"
  type        = number
  sensitive   = true
}

variable "db_name" {
  description = "The database name"
  type        = string
  sensitive   = true
}
