data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "main" {
  name_prefix   = "dockpaas-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  vpc_security_group_ids = [aws_security_group.ec2.id]

  user_data = base64encode(templatefile("${path.module}/../scripts/user_data.sh", {
    region              = var.region
    ecr_repository_url  = aws_ecr_repository.ecr_dock.repository_url
    s3_bucket           = aws_s3_bucket.deployment_reports.id
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "dockpaas-instance"
      Project     = "DockPaas"
      Environment = "dev"
      AutoDeploy  = "true"
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
}

resource "aws_autoscaling_group" "main" {
  name                = "dockpaas-asg"
  vpc_zone_identifier = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  target_group_arns   = [aws_lb_target_group.main.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300
  min_size            = 1
  max_size            = 3
  desired_capacity    = 2

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "dockpaas-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "DockPaas"
    propagate_at_launch = true
  }

  tag {
    key                 = "AutoDeploy"
    value               = "true"
    propagate_at_launch = true
  }
}
