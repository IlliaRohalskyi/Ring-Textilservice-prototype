# QuickSight Infrastructure Support for Ring Textilservice
# This module creates the necessary IAM roles, policies, and secrets
# to support QuickSight connection to PostgreSQL RDS
# Note: Networking components are managed by the networking module

# IAM Role for QuickSight to access VPC resources
resource "aws_iam_role" "quicksight_vpc_role" {
  name = "${var.project_name}-quicksight-vpc-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "quicksight.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-quicksight-vpc-role"
    Purpose = "QuickSight VPC access for database connectivity"
  }
}

# Custom IAM Policy for QuickSight VPC operations
resource "aws_iam_policy" "quicksight_vpc_policy" {
  name        = "${var.project_name}-quicksight-vpc-policy"
  description = "Policy for QuickSight to access VPC resources and RDS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:ModifyNetworkInterfaceAttribute",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeNetworkInterfaces",
          "ec2:CreateNetworkInterfacePermission"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the custom policy to the IAM role
resource "aws_iam_role_policy_attachment" "quicksight_vpc_policy_attachment" {
  role       = aws_iam_role.quicksight_vpc_role.name
  policy_arn = aws_iam_policy.quicksight_vpc_policy.arn
}



# IAM policy for QuickSight to access the main database secret
resource "aws_iam_policy" "quicksight_secrets_policy" {
  name        = "${var.project_name}-quicksight-secrets-policy"
  description = "Policy for QuickSight to access database credentials"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.db_secret_arn
      }
    ]
  })
}

# Attach secrets policy to QuickSight role
resource "aws_iam_role_policy_attachment" "quicksight_secrets_policy_attachment" {
  role       = aws_iam_role.quicksight_vpc_role.name
  policy_arn = aws_iam_policy.quicksight_secrets_policy.arn
}