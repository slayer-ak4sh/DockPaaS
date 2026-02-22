resource "aws_cloudwatch_event_rule" "ecr_push" {
  name        = "dockpaas-ecr-push-rule"
  description = "Trigger deployment when new image is pushed to ECR"

  event_pattern = jsonencode({
    source      = ["aws.ecr"]
    detail-type = ["ECR Image Action"]
    detail = {
      action-type     = ["PUSH"]
      result          = ["SUCCESS"]
      repository-name = [aws_ecr_repository.ecr_dock.name]
    }
  })

  tags = {
    Name    = "dockpaas-ecr-push-rule"
    Project = "DockPaas"
  }
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.ecr_push.name
  target_id = "DockPaaSDeploymentTrigger"
  arn       = aws_lambda_function.deployment_trigger.arn
}
