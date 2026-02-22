output "ecr_repository_url" {
  value = aws_ecr_repository.ecr_dock.repository_url
  description = "The URL of the ECR repository"
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
  description = "DNS name of the Application Load Balancer"
}

output "s3_website_url" {
  value = aws_s3_bucket_website_configuration.deployment_reports.website_endpoint
  description = "S3 static website URL for deployment reports"
}

output "lambda_function_name" {
  value = aws_lambda_function.deployment_trigger.function_name
  description = "Name of the Lambda deployment trigger function"
}