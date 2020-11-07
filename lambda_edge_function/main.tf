data "archive_file" "lambda_edge_zip" {
  type        = "zip"
  output_path = "${path.root}/.terraform/artifacts/${var.function_name}.zip"

  source {
    content  = file(var.bundle_file_name)
    filename = "main.js"
  }

  source {
    content  = jsonencode(var.configuration)
    filename = "configuration.json"
  }
}

resource "aws_lambda_function" "lambda_edge_function" {
  description      = var.description
  filename         = data.archive_file.lambda_edge_zip.output_path
  function_name    = var.function_name
  role             = var.lambda_role_arn
  handler          = "main.${var.handler_name}"
  runtime          = "nodejs12.x"
  source_code_hash = data.archive_file.lambda_edge_zip.output_base64sha256
  timeout          = 5
  memory_size      = 128
  publish          = true
  provider         = aws.us-east-1
}

/*
These are proxy provider blocks, they just declare that the calling module must explicitly
pass aws.us-east-1 as an additional provider
*/
provider "aws" {
  alias = "us-east-1"
}