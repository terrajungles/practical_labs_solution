data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default_vpc" {
  vpc_id = data.aws_vpc.default.id
}

resource "aws_security_group" "alb_allow_web" {
  name        = "alb_allow_web"
  description = "Allow HTTP inbound traffic for Load Balancer"

  ingress {
    description = "HTTP VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "alb_allow_web"
    Environment = var.environment
  }
}

resource "aws_lb" "server_alb" {
  name               = "server-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_allow_web.id]
  subnets            = data.aws_subnet_ids.default_vpc.ids

  tags = {
    Environment = var.environment
  }
}

resource "aws_lb_listener" "server" {
  load_balancer_arn = aws_lb.server_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.server_alb.id
  }
}

resource "aws_lb_target_group" "server_alb" {
  name     = "server-alb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}
