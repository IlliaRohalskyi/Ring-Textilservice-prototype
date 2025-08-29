# Random ID for unique bucket names
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 Bucket for Data Storage
resource "aws_s3_bucket" "data_bucket" {
  bucket = "${var.project_name}-data-bucket-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket_versioning" "data_bucket_versioning" {
  bucket = aws_s3_bucket.data_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket for Scripts
resource "aws_s3_bucket" "scripts_bucket" {
  bucket = "${var.project_name}-scripts-bucket-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket_versioning" "scripts_bucket_versioning" {
  bucket = aws_s3_bucket.scripts_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

locals {
  s3_buckets = {
    data    = aws_s3_bucket.data_bucket.id
    scripts = aws_s3_bucket.scripts_bucket.id
  }
}

resource "aws_s3_bucket_policy" "enforce_https" {
  for_each = local.s3_buckets

  bucket = each.value

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "EnforceHttps",
        Effect    = "Deny",
        Principal = "*",
        Action    = "s3:*",
        Resource  = [
          "arn:aws:s3:::${each.value}",
          "arn:aws:s3:::${each.value}/*"
        ],
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

resource "aws_db_parameter_group" "data_rds_parameters" {
  name   = "${var.project_name}-data-rds-params"
  family = "postgres17"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  tags = {
    Name = "${var.project_name} Data RDS Parameter Group"
  }
}

resource "aws_db_instance" "project_rds" {
  identifier             = "${var.project_name}-data-db"
  db_name                = "${lower(replace(var.project_name, "-", "_"))}_data"
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "17.2"
  instance_class         = var.data_instance_class
  username               = var.data_db_username
  password               = var.data_db_password
  skip_final_snapshot    = false
  final_snapshot_identifier = "${var.project_name}-final-snapshot-${random_id.bucket_suffix.hex}"
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  deletion_protection     = false
  multi_az                = true
  db_subnet_group_name    = var.db_subnet_group_id
  vpc_security_group_ids  = [var.rds_security_group_id]
  publicly_accessible     = false
  storage_encrypted       = true
  parameter_group_name    = aws_db_parameter_group.data_rds_parameters.name

  tags = {
    Name = "${var.project_name} Data"
  }
}