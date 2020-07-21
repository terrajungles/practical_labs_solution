resource "aws_autoscaling_group" "server_asg" {
  availability_zones = ["ap-northeast-1a"]
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1

  launch_template {
    id      = aws_launch_template.server.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.server_alb.id]
}

resource "aws_launch_template" "server" {
  name                   = "server-launch-template"
  image_id               = "ami-08d175f1b493f205f"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  key_name               = "ground-deployer"

  user_data = base64encode(templatefile("./server.sh", {
    app_id     = var.app_id,
    master_key = var.master_key,
    db_ip      = aws_instance.database.private_ip,
    db_port    = var.db_port
    public_dns = aws_lb.server_alb.dns_name
  }))

  placement {
    availability_zone = "ap-northeast-1a"
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "Parse-Server"
      Deployer    = "terraform"
      Environment = var.environment
    }
  }
}

resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow HTTP inbound traffic"

  ingress {
    description = "HTTP VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_allow_web.id]
  }

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_allow_web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "allow_web"
    Environment = var.environment
  }
}