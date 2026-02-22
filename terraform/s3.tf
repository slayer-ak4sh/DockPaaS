resource "aws_s3_bucket" "deployment_reports" {
  bucket = "dockpaas-deployment-reports-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name    = "dockpaas-deployment-reports"
    Project = "DockPaas"
  }
}

resource "aws_s3_bucket_website_configuration" "deployment_reports" {
  bucket = aws_s3_bucket.deployment_reports.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "deployment_reports" {
  bucket = aws_s3_bucket.deployment_reports.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "deployment_reports" {
  bucket = aws_s3_bucket.deployment_reports.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.deployment_reports.arn}/*"
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.deployment_reports]
}

data "aws_caller_identity" "current" {}
