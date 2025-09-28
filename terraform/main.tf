terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.82.2"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Budget resource stays in main
resource "aws_budgets_budget" "budget" {
  name         = "budget"
  budget_type  = "COST"
  limit_amount = "100"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
}

module "networking" {
  source  = "./modules/networking"
  project_name = var.project_name
  ip_address = var.ip_address
}

module "storage" {
  source  = "./modules/storage"
  project_name = var.project_name
  data_instance_class = var.data_instance_class
  db_subnet_group_id = module.networking.db_subnet_group_id
  rds_security_group_id = module.networking.rds_security_group_id
  data_db_username = var.data_db_username
  data_db_password = var.data_db_password

  depends_on = [ module.networking ]
}

module "secretsmanager" {
  source  = "./modules/secretsmanager"
  db_username = var.data_db_username
  db_password = var.data_db_password
  db_host = module.storage.db_host
  db_port = module.storage.db_port
  db_name = module.storage.db_name

  depends_on = [ module.storage ]
}

module "compute" {
  source = "./modules/compute"
  project_name = var.project_name
  aws_region = var.aws_region
  aws_account_id = var.aws_account_id
  scripts_bucket = module.storage.scripts_bucket
  data_bucket = module.storage.data_bucket
  db_host = module.storage.db_host
  db_port = module.storage.db_port
  db_name = module.storage.db_name
  vpc_subnet_id = module.networking.private_subnet_a_id
  glue_security_group_id = module.networking.glue_security_group_id
  db_secret_id = module.secretsmanager.db_secret_id
  availability_zone = module.networking.subnet_a_availability_zone
  
  # Lambda variables
  db_secret_arn = module.secretsmanager.db_secret_arn
  db_secret_name = module.secretsmanager.db_secret_name
  private_subnet_b_id = module.networking.private_subnet_b_id
  lambda_security_group_id = module.networking.lambda_security_group_id

  depends_on = [ module.storage, module.secretsmanager, module.networking ]
}

module "step_functions" {
  source       = "./modules/step_functions"
  project_name = var.project_name
  aws_region   = var.aws_region
  glue_job_name = module.compute.glue_job_name

  depends_on = [ module.compute ]
}

 module "trigger" {
  source       = "./modules/triggers"
  aws_region   = var.aws_region
  s3_bucket_name = module.storage.data_bucket
  step_function_arn = module.step_functions.step_function_arn

  depends_on = [ module.networking, module.step_functions ]
}