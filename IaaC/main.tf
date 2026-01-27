########################################
# LOCALS
########################################
locals {
  name_prefix = "${var.project}-${var.application}-${var.environment}-${var.location_short}"

  tags = {
    project     = var.project
    application = var.application
    environment = var.environment
    location    = var.location
    blockcode   = var.blockcode
  }
}

########################################
# VPC
########################################
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = local.tags
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

########################################
# SUBNETS
########################################
data "aws_availability_zones" "azs" {}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet("10.0.0.0/16", 4, count.index)
  availability_zone       = data.aws_availability_zones.azs.names[count.index]
  map_public_ip_on_launch = true
  tags = local.tags
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id             = aws_vpc.main.id
  cidr_block         = cidrsubnet("10.0.0.0/16", 4, count.index + 4)
  availability_zone  = data.aws_availability_zones.azs.names[count.index]
  tags = local.tags
}

########################################
# ROUTES
########################################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

########################################
# S3 (FRONTEND HOSTING)
########################################
resource "aws_s3_bucket" "frontend" {
  bucket = "${local.name_prefix}-frontend"
  tags   = local.tags
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls   = false
  block_public_policy = false
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.frontend.arn}/*"
    }]
  })
}

########################################
# SECURITY GROUPS
########################################
resource "aws_security_group" "lambda_sg" {
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }
}

########################################
# RDS MYSQL
########################################
resource "aws_db_subnet_group" "db" {
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_db_instance" "mysql" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = "studentdb"
  username               = "admin"
  password               = var.db_password
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db.name
}

########################################
# IAM ROLE FOR LAMBDA
########################################
resource "aws_iam_role" "lambda_role" {
  name = "${local.name_prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

########################################
# LAMBDA FUNCTION
########################################
resource "aws_lambda_function" "backend" {
  function_name = "${local.name_prefix}-backend"
  role          = aws_iam_role.lambda_role.arn
  runtime       = "nodejs18.x"
  handler       = "index.handler"
  filename      = "backend.zip"

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      DB_HOST = aws_db_instance.mysql.address
      DB_USER = "admin"
      DB_PASSWORD = var.db_password
      DB_NAME = "studentdb"
    }
  }
}

########################################
# API GATEWAY (SWAGGER INJECTED)
########################################
locals {
  lambda_invoke_arn = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.backend.arn}/invocations"
}

resource "aws_api_gateway_rest_api" "api" {
  name = "${local.name_prefix}-api"

  body = templatefile(
    "${path.module}/swagger.yaml.tpl",
    {
      lambda_invoke_arn = local.lambda_invoke_arn
    }
  )
}

resource "aws_api_gateway_deployment" "deploy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "prod"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

########################################
# OUTPUTS
########################################
output "frontend_url" {
  value = aws_s3_bucket_website_configuration.frontend.website_endpoint
}

output "api_url" {
  value = aws_api_gateway_deployment.deploy.invoke_url
}
