variable "project_name" {
  description = "Name of the project - used for resource naming"
  type        = string
}

variable "ip_address" {
  description = "Your IP address in CIDR notation (e.g. 1.2.3.4/32)"
  type        = string
  sensitive   = true
}