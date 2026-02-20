resource "aws_ecr_repository" "ecr_dock" {
  name = "dockpaas-java"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    name = "dockpaas-java"
    Project = "DockPaas"
    Environment = "dev"
    ManagedBy = "Terraform"
  }
}

resource "aws_ecr_lifecycle_policy" "dockpaas_java_policy" {
  repository = aws_ecr_repository.ecr_dock.name

  policy = jsonencode({
    rules = [
      # Rule 1 – Highest priority: Clean up untagged images aggressively first
      {
        rulePriority = 1
        description  = "Expire untagged images after 7 days"

        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }

        action = {
          type = "expire"
        }
      },

      # Rule 2 – Lowest priority: After specific cleanup, apply the overall cap on remaining images
      {
        rulePriority = 2
        description  = "Keep last 10 images (tagged + remaining untagged), expire older ones"

        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }

        action = {
          type = "expire"
        }
      }
    ]
  })
}