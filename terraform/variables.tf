variable "region" {
  default = "us-east-2"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "asg_min_size" {
  default = 1
}

variable "asg_max_size" {
  default = 3
}

variable "asg_desired_capacity" {
  default = 2
}

# variable "albname" {
#   default = ""
# }