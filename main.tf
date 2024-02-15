provider "aws" {
  region = "us-east-2"
}

resource "aws_launch_configuration" "example" {
  image_id           = "ami-0fb653ca2d3203ac1"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

  # Required when using a launch configuration with an auto scaling group.
  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_security_group" "instance" {

  name = "terraform-example-instance"

  ingress {

    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

}

resource "aws_autoscaling_group" "example" {

  launch_configuration = "aws_launch_configuration.example.name"
  vpc_zone_identifier = data.aws_subnets.default.ids

  max_size = 10
  min_size = 2

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "terraform-asg-example"
  }

}

variable "server_port" {

  description = "The port the server will use for HTTP requests"
  type = number
  default = 8080

}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

}

