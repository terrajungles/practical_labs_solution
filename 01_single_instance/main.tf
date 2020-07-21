terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  version = "~> 2.0"
  region  = "ap-northeast-1"
}

resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow HTTP inbound traffic"

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
    Name       = "allow_web"
    Environmet = var.environment
  }
}

resource "aws_instance" "server" {
  ami             = "ami-08d175f1b493f205f"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.allow_web.name]
  key_name        = "ground-deployer"

  user_data = templatefile("./user_data.sh", {
    app_id = var.app_id,
    master_key = var.master_key
  })

  tags = {
    Name        = "Parse-Server"
    Deployer    = "terraform"
    Environment = var.environment
  }
}