terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# S3
resource "aws_s3_bucket" "input_bucket" {
  bucket = "serverless-image-input-bucket"
}

resource "aws_s3_bucket" "output_bucket" {
  bucket = "serverless-image-out-bucket"
}

# IAM Role
resource "aws_iam_role" "lambda_role" {
  name = "lambda-image-processing-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy_attachment" "lambda_policy" {
  name       = "lambda-s3-rekognition-policy"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_policy_attachment" "lambda_rekognition_policy" {
  name       = "lambda-rekognition-policy"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonRekognitionFullAccess"
}

# Lambda
resource "aws_lambda_function" "image_processor" {
  filename      = "lambda_function.zip"
  function_name = "image-processing-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  timeout       = 10

  source_code_hash = filebase64sha256("lambda_function.zip")

  layers = ["arn:aws:lambda:us-east-1:770693421928:layer:Klayers-p39-pillow:1"]

  environment {
    variables = {
      OUTPUT_BUCKET = aws_s3_bucket.output_bucket.id
    }
  }

}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  principal     = "s3.amazonaws.com"
  function_name = aws_lambda_function.image_processor.function_name
  source_arn    = aws_s3_bucket.input_bucket.arn
}

# S3 Triggers
resource "aws_s3_bucket_notification" "s3_trigger" {
  bucket = aws_s3_bucket.input_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.image_processor.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_function.image_processor] # Ensure the lambda function is created first
}

# Create new log group for lambda function
resource "aws_cloudwatch_log_group" "image-processing-log-group" {
  name = "/aws/lambda/${aws_lambda_function.image_processor.function_name}"

  tags = {
    Environment = "testing"
  }
}

resource "aws_lambda_permission" "logging" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_processor.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = aws_cloudwatch_log_group.image-processing-log-group.arn
}