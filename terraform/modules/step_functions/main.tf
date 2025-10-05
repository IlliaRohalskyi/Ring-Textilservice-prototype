# IAM Role for Step Functions
resource "aws_iam_role" "step_function_role" {
  name = "${var.project_name}-step-function-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Step Functions to invoke Glue
resource "aws_iam_role_policy" "step_function_policy" {
  name = "${var.project_name}-step-function-policy"
  role = aws_iam_role.step_function_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:StartJobRun",
          "glue:GetJobRun",
          "glue:GetJobRuns",
          "glue:BatchStopJobRun"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = var.upsert_lambda_arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Log Group for Step Functions
resource "aws_cloudwatch_log_group" "step_function_logs" {
  name              = "/aws/stepfunctions/${var.project_name}-data-processing"
  retention_in_days = 14
}

# Step Function State Machine
resource "aws_sfn_state_machine" "data_processing_workflow" {
  name     = "${var.project_name}-data-processing-workflow"
  role_arn = aws_iam_role.step_function_role.arn

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.step_function_logs.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }

  definition = jsonencode({
    Comment = "Data processing workflow that triggers Glue job"
    StartAt = "StartGlueJob"
    States = {
      StartGlueJob = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = var.glue_job_name
          Arguments = {
            "--s3_input_path.$" = "$.s3_input_path"
          }
        }
        Next = "UpsertData"
        Catch = [
          {
            ErrorEquals = ["States.TaskFailed", "States.Timeout"]
            Next        = "JobFailed"
            ResultPath  = "$.error"
          }
        ]
        Retry = [
          {
            ErrorEquals     = ["States.TaskFailed"]
            IntervalSeconds = 30
            MaxAttempts     = 2
            BackoffRate     = 2.0
          }
        ]
      }
      UpsertData = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = var.upsert_lambda_arn
          Payload = {
            "source" = "step-function"
          }
        }
        Next = "JobSucceeded"
        Catch = [
          {
            ErrorEquals = ["States.TaskFailed", "States.Timeout"]
            Next        = "JobFailed"
            ResultPath  = "$.upsert_error"
          }
        ]
        Retry = [
          {
            ErrorEquals     = ["States.TaskFailed"]
            IntervalSeconds = 10
            MaxAttempts     = 2
            BackoffRate     = 2.0
          }
        ]
      }
      JobSucceeded = {
        Type = "Succeed"
      }
      JobFailed = {
        Type = "Fail"
        Cause = "Glue job failed"
        Error = "JobExecutionFailed"
      }
    }
  })

  tags = {
    Project = var.project_name
  }
}
