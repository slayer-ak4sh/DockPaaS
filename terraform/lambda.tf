data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/../scripts/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "deployment_trigger" {
  filename         = data.archive_file.lambda.output_path
  function_name    = "dockpaas-deployment-trigger"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime         = "python3.12"
  timeout         = 60

  environment {
    variables = {
      REGION = var.region
    }
  }

  tags = {
    Name    = "dockpaas-deployment-trigger"
    Project = "DockPaas"
  }
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.deployment_trigger.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecr_push.arn
}
