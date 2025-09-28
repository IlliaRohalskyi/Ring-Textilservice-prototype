resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway for public subnets
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Private subnets for Glue and other services
resource "aws_subnet" "private_subnet_a" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-central-1a"
  tags = {
    Name = "${var.project_name}-private-subnet-a"
  }
  
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-central-1b"
  tags = { Name = "${var.project_name}-private-subnet-b" }
}

# Public subnets
resource "aws_subnet" "rds_public_subnet_a" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_name}-rds-public-subnet-a"
  }
}

resource "aws_subnet" "rds_public_subnet_b" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_name}-rds-public-subnet-b"
  }
}

# Route table for public subnets (RDS only)
resource "aws_route_table" "rds_public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "${var.project_name}-rds-public-route-table"
  }
}

# Associate public subnets with route table
resource "aws_route_table_association" "rds_public_subnet_a_association" {
  subnet_id      = aws_subnet.rds_public_subnet_a.id
  route_table_id = aws_route_table.rds_public_rt.id
}

resource "aws_route_table_association" "rds_public_subnet_b_association" {
  subnet_id      = aws_subnet.rds_public_subnet_b.id
  route_table_id = aws_route_table.rds_public_rt.id
}

# DB subnet group using PRIVATE subnets for RDS
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [
    aws_subnet.private_subnet_a.id,
    aws_subnet.private_subnet_b.id
  ]
  tags = { Name = "${var.project_name}-db-subnet-group" }
}

# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = aws_vpc.main_vpc.id

  # Allow access from within VPC (private subnets)
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main_vpc.cidr_block]
    description = "Allow PostgreSQL access from within VPC"
  }

  # Allow access from Glue
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.glue_sg.id]
    description     = "Allow PostgreSQL access from Glue"
  }

  # Allow access from Lambda
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
    description     = "Allow PostgreSQL access from Lambda"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "rds-sg"
  }
}

data "aws_prefix_list" "s3" {
  name = "com.amazonaws.eu-central-1.s3"
}

resource "aws_security_group" "glue_sg" {
  name        = "${var.project_name}-glue-sg"
  description = "Security group for AWS Glue jobs"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description      = "Allow Glue self communication"
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    self             = true
  }

  ingress {
    description = "Allow inbound HTTPS from same security group"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    self        = true
  }

  egress {
    description = "Allow all egress for Glue (self-referencing)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    description      = "Allow outbound to RDS (within VPC)"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.main_vpc.cidr_block]
  }

  # Allow outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description     = "Allow HTTPS to S3 via Gateway VPC Endpoint"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [data.aws_prefix_list.s3.id]
  }

    egress {
    description     = "Allow HTTPS to VPC endpoints"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.vpc_endpoint_sg.id]
  }

  tags = {
    Name = "${var.project_name}-glue-sg"
  }
}

# Security group for VPC endpoints
resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "${var.project_name}-vpc-endpoint-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "Allow HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main_vpc.cidr_block]
  }
}

# Security group for Lambda functions
resource "aws_security_group" "lambda_sg" {
  name        = "${var.project_name}-lambda-sg"
  description = "Security group for Lambda functions"
  vpc_id      = aws_vpc.main_vpc.id

  # Allow outbound HTTPS for AWS API calls
  egress {
    description = "Allow HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound to RDS
  egress {
    description     = "Allow outbound to RDS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks     = [aws_vpc.main_vpc.cidr_block]
  }

  # Allow all outbound within VPC
  egress {
    description = "Allow all outbound within VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main_vpc.cidr_block]
  }

  tags = {
    Name = "${var.project_name}-lambda-sg"
  }
}

# VPC Endpoint for S3 (Gateway endpoint - no security group needed)
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main_vpc.id
  service_name = "com.amazonaws.eu-central-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [aws_route_table.private_rt.id]
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:ListAllMyBuckets",
          "s3:GetBucketLocation"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-s3-endpoint"
  }
}

# Route table for private subnets
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# Associate S3 endpoint with private route table
resource "aws_vpc_endpoint_route_table_association" "s3_private" {
  route_table_id  = aws_route_table.private_rt.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

# Associate private subnets with route table
resource "aws_route_table_association" "private_subnet_a_association" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_subnet_b_association" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_rt.id
}

# VPC Endpoint for CloudWatch Logs
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main_vpc.id
  service_name        = "com.amazonaws.eu-central-1.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-logs-endpoint"
  }
}

# VPC Endpoint for Secrets Manager (needed for Lambda to access DB credentials)
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main_vpc.id
  service_name        = "com.amazonaws.eu-central-1.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-secretsmanager-endpoint"
  }
}