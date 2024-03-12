# data.tf

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available_zones" {
  state = "available"
}

data "archive_file" "lambda1" {
  type        = "zip"
  source_dir  = "lambdas/function"
  output_path = "lambdas/lambda_function.zip"
}
