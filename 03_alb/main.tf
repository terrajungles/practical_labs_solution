terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  version = "~> 2.0"
  region  = "ap-northeast-1"
}

resource "aws_security_group" "mongo_db" {
  name        = "mongo_db"
  description = "Security group of Mongo DB"

  ingress {
    description = "HTTP VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "From Web tier"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.allow_web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name       = "mongo_db"
    Environmet = var.environment
  }
}

resource "aws_instance" "database" {
  ami             = "ami-08d175f1b493f205f"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.mongo_db.name]
  key_name        = "ground-deployer"

  user_data = templatefile("./mongo.sh", {
    db_port = var.db_port
  })

  tags = {
    Name        = "Parse-Server-DB"
    Deployer    = "terraform"
    Environment = var.environment
  }
}