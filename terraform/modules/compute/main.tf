# data "archive_file" "lambda_zip" {
#   type       = "zip"
#   source_dir = "${path.module}/../../../src/lambda"
#   output_path = "${path.module}/../../lambda_payload.zip"
# }

# resource "aws_s3_object" "lambda_zip" {
#   bucket = var.scripts_bucket
#   key    = "lambda/lambda_payload.zip"
#   source = data.archive_file.lambda_zip.output_path
#   etag   = filemd5(data.archive_file.lambda_zip.output_path)
#   acl    = "private"
# }

# resource "aws_iam_role" "lambda_exec_role" {
#   name = "${var.project_name}-lambda-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Action = "sts:AssumeRole"
#       Effect = "Allow"
#       Principal = { Service = "lambda.amazonaws.com" }
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "lambda_basic" {
#   role       = aws_iam_role.lambda_exec_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# }

# resource "aws_iam_role_policy" "lambda_quicksight_policy" {
#   name = "${var.project_name}-lambda-quicksight-policy"
#   role = aws_iam_role.lambda_exec_role.id

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Action = [
#           "quicksight:CreateIngestion",
#           "quicksight:DescribeIngestions",
#           "quicksight:ListIngestions",
#           "quicksight:DescribeDataSet"
#         ],
#         Resource = "arn:aws:quicksight:${var.aws_region}:${var.aws_account_id}:dataset/*"
#       },
#       {
#         Effect = "Allow",
#         Action = [
#           "logs:CreateLogGroup",
#           "logs:CreateLogStream",
#           "logs:PutLogEvents"
#         ],
#         Resource = "arn:aws:logs:*:*:*"
#       }
#     ]
#   })
# }

# resource "aws_lambda_function" "quicksight_refresh" {
#   function_name = "${var.project_name}-quicksight-refresh"
#   s3_bucket     = var.scripts_bucket
#   s3_key        = aws_s3_object.lambda_zip.key
#   role          = aws_iam_role.lambda_exec_role.arn
#   handler       = "lambda_function.lambda_handler"
#   runtime       = "python3.11"
#   source_code_hash = data.archive_file.lambda_zip.output_base64sha256
#   timeout        = 60

#   environment {
#     variables = {
#       QUICKSIGHT_ACCOUNT_ID  = var.quicksight_account_id
#       QUICKSIGHT_DATA_SET_ID = var.quicksight_data_set_id
#     }
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# Get all .whl files from the wheels directory
locals {
  wheel_files = fileset("${path.module}/../../../wheels", "*.whl")
}

# Upload each .whl file individually to S3
resource "aws_s3_object" "wheel_files" {
  for_each = local.wheel_files
  
  bucket = var.scripts_bucket
  key    = "glue/wheels/${each.value}"
  source = "${path.module}/../../../wheels/${each.value}"
  etag   = filemd5("${path.module}/../../../wheels/${each.value}")
  acl    = "private"
}

resource "aws_s3_object" "glue_script" {
  bucket = var.scripts_bucket
  key    = "glue/glue_job.py"
  source = "${path.module}/../../../src/glue/glue_job.py"
  etag   = filemd5("${path.module}/../../../src/glue/glue_job.py")
  acl    = "private"
}

resource "aws_iam_role" "glue_job_role" {
  name = "${var.project_name}-glue-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "glue.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_job_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "glue_job_minimal_policy" {
  name = "${var.project_name}-glue-minimal-policy"
  role = aws_iam_role.glue_job_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "S3ScriptAndList"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.scripts_bucket}",
          "arn:aws:s3:::${var.scripts_bucket}/*",
          "arn:aws:s3:::${var.data_bucket}",
          "arn:aws:s3:::${var.data_bucket}/*"
        ]
      },
      {
        Sid = "S3TempWrite"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.scripts_bucket}/glue-temp/*"
        ]
      },
      {
        Sid = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Sid = "EC2ENI"
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:CreateTags"
        ]
        Resource = "*"
      },
      {
        Sid = "SecretsManagerAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.db_secret_id
      }
    ]
  })
}

resource "aws_glue_connection" "db_connection" {
  name            = "glue-db-connection"
  description     = "Glue connection with credentials from Secrets Manager"
  connection_type = "JDBC"

  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:postgresql://${var.db_host}:${var.db_port}/${var.db_name}"
    SECRET_ID           = var.db_secret_id
  }

  physical_connection_requirements {
    subnet_id             = var.vpc_subnet_id
    security_group_id_list = [var.glue_security_group_id]
    availability_zone     = var.availability_zone
  }
}


resource "aws_glue_job" "data_processing_job" {
  name     = "${var.project_name}-glue-job"
  role_arn = aws_iam_role.glue_job_role.arn

  command {
    name           = "glueetl"
    python_version = "3"
    script_location = "s3://${var.scripts_bucket}/${aws_s3_object.glue_script.key}"
  }

  connections = [aws_glue_connection.db_connection.name]

  default_arguments = {
    "--TempDir"                          = "s3://${var.scripts_bucket}/glue-temp/"
    "--enable-continuous-cloudwatch-log" = "true"
    "--job-language"                    = "python"
    "--enable-auto-scaling"               = "true"
    "--extra-py-files"                   = join(",", [for file in local.wheel_files : "s3://${var.scripts_bucket}/glue/wheels/${file}"])
  }

  number_of_workers = var.glue_max_capacity
  worker_type = var.glue_worker_type

  max_retries  = 1
  timeout     = 60
  glue_version = "5.0"

  execution_property {
    max_concurrent_runs = 10
  }

  depends_on = [
    aws_s3_object.glue_script,
    aws_s3_object.wheel_files
  ]
}