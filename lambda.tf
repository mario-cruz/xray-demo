################################################################################
# Lambda Role
################################################################################
resource "aws_iam_role" "image_api_lambda_role" {
  name        = "image-api-lambda-role"
  description = "Allows Lambda to save images on a S3 bucket"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_pol_attachment" {
  role       = aws_iam_role.image_api_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "cw_pol_attachment" {
  role       = aws_iam_role.image_api_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_iam_role_policy_attachment" "aws_xray_write_only_access" {
  role       = aws_iam_role.image_api_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}
resource "aws_iam_role_policy_attachment" "aws_xray_deamon_write_access" {
  role       = aws_iam_role.image_api_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

################################################################################
# Lamda Start & Stop
################################################################################
resource "aws_lambda_function" "image_api_scraper" {
  function_name = "image-api-scraper"
  filename      = "lambdas/lambda_function.zip"
  role          = aws_iam_role.image_api_lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda1.output_base64sha256
  runtime = "python3.9"
  timeout = 10

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.img_api_bucket.id
    }
  }
  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_function_url" "image_api_scraper_url" {
  function_name      = aws_lambda_function.image_api_scraper.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "allow_ecs_task_role_to_call_lambda" {
  statement_id = "AllowExecutionFromRole"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_api_scraper.function_name
  principal = aws_iam_role.ecs_task_role.arn
}