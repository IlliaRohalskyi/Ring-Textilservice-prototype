# # Create a QuickSight data source connecting to your database (e.g., RDS Postgres)
# resource "aws_quicksight_data_source" "example_db" {
#   aws_account_id = var.aws_account_id
#   data_source_id = "example-db-source"
#   name           = "Example DB Source"
#   type           = "POSTGRESQL"  # Change to your DB type
#   data_source_parameters {
#     postgresql_parameters {
#       host     = var.db_host
#       port     = var.db_port
#       database = var.db_name
#     }
#   }

#   credentials {
#     credential_pair {
#       username = var.db_user
#       password = var.db_password
#     }
#   }

#   permissions {
#     principal = "arn:aws:quicksight:${var.aws_region}:${var.aws_account_id}:user/default/${var.quicksight_user}"
#     actions   = [
#       "quicksight:DescribeDataSource",
#       "quicksight:DescribeDataSourcePermissions",
#       "quicksight:UpdateDataSource",
#       "quicksight:DeleteDataSource",
#       "quicksight:UpdateDataSourcePermissions"
#     ]
#   }
# }

# # Create a QuickSight dataset from the data source
# resource "aws_quicksight_data_set" "example_data_set" {
#   aws_account_id = var.aws_account_id
#   data_set_id    = "example-data-set"
#   name           = "Example Data Set"
#   import_mode    = "DIRECT_QUERY" # or SPICE for in-memory

#   physical_table_map = {
#     example_table = {
#       relational_table = {
#         data_source_arn = aws_quicksight_data_source.example_db.arn
#         schema          = "public"
#         name            = var.db_table_name
#         input_columns = [
#           { name = "id", type = "INTEGER" },
#           { name = "name", type = "STRING" },
#           { name = "date", type = "DATETIME" }
#         ]
#       }
#     }
#   }

#   permissions {
#     principal = "arn:aws:quicksight:${var.aws_region}:${var.aws_account_id}:user/default/${var.quicksight_user}"
#     actions   = [
#       "quicksight:DescribeDataSet",
#       "quicksight:DescribeDataSetPermissions",
#       "quicksight:UpdateDataSet",
#       "quicksight:DeleteDataSet",
#       "quicksight:UpdateDataSetPermissions"
#     ]
#   }
# }

# # Create a simple QuickSight dashboard referencing the dataset
# resource "aws_quicksight_dashboard" "example_dashboard" {
#   aws_account_id    = var.aws_account_id
#   dashboard_id      = "example-dashboard"
#   name              = "Example Dashboard"
#   source_entity {
#     source_template {
#       arn = var.quicksight_template_arn
#       data_set_references = [
#         {
#           data_set_placeholder = "DataSet1"
#           data_set_arn         = aws_quicksight_data_set.example_data_set.arn
#         }
#       ]
#     }
#   }

#   permissions {
#     principal = "arn:aws:quicksight:${var.aws_region}:${var.aws_account_id}:user/default/${var.quicksight_user}"
#     actions = [
#       "quicksight:DescribeDashboard",
#       "quicksight:ListDashboardVersions",
#       "quicksight:UpdateDashboard",
#       "quicksight:DeleteDashboard",
#       "quicksight:QueryDashboard",
#       "quicksight:UpdateDashboardPermissions"
#     ]
#   }
# }
