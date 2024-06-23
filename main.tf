terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.0"
    }
  }
}


provider "aws" {
    profile = "${var.profile}"
    region = "${var.region}"

}


data "aws_vpc" "default" {
 default = true
}

resource "aws_default_subnet" "subnet1" {
  availability_zone = "us-east-1c"

  tags = {
    Name = "Default subnet for us-east-1c"
  }
}

resource "aws_default_subnet" "subnet2" {
  availability_zone = "us-east-1d"

  tags = {
    Name = "Default subnet for us-east-1d"
  }
}

resource "aws_security_group" "web_server_sg_http" {
 name        = "web-server-sg-tf"
 description = "Allow HTTP to web server"
 vpc_id      = data.aws_vpc.default.id

 ingress {
   description = "HTTP ingress"
   from_port   = 80
   to_port     = 80
   protocol    = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
 }

egress {
   from_port   = 0
   to_port     = 0
   protocol    = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }
}


resource "aws_launch_template" "template" {
  name_prefix     = "asg-template"
  image_id        = "${var.ami-id}"
  instance_type   = "${var.instance-type}"
  key_name = var.key_name != null ? var.key_name : null
  vpc_security_group_ids = [aws_security_group.web_server_sg_http.id]

  user_data = filebase64("${path.module}/ngixBootstrap.sh")
  
}
resource "aws_elb" "load_balancer" {

  name               = "elastic-load-balancer"
  internal           = false
  subnets            = [aws_default_subnet.subnet1.id, aws_default_subnet.subnet2.id,]

  cross_zone_load_balancing = true

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

    health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }
  security_groups    = [aws_security_group.web_server_sg_http.id]
}

resource "aws_autoscaling_group" "autoscale" {
  name                  = "autoscaling-group-assignment"
  availability_zones    = [aws_default_subnet.subnet1.id, aws_default_subnet.subnet2.id,]
  desired_capacity      = 2
  max_size              = 5
  min_size              = 2
  health_check_type     = "${var.health_check_type}"
  termination_policies  = ["OldestInstance"]
  vpc_zone_identifier   = [aws_default_subnet.subnet1.id, aws_default_subnet.subnet2.id,]
  load_balancers = [aws_elb.load_balancer.id]
  launch_template {
    id      = aws_launch_template.template.id
    version = "$Latest"
  }

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTotalInstances",
    "GroupTotalCapacity"
  ]
}

resource "aws_autoscaling_attachment" "auto_attachment" {
  autoscaling_group_name = aws_autoscaling_group.autoscale.id
  elb   = aws_elb.load_balancer.id
}
