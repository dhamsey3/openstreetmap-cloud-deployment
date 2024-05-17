provider "aws" {
  region = "us-west-2" # Change to your preferred region
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Create subnets
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# Create an internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# Create a route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Associate the route table with the public subnet
resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Create a security group
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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

# IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy for EC2 Role
resource "aws_iam_policy" "ec2_policy" {
  name        = "ec2_policy"
  description = "IAM policy for EC2 role"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:*",
          "cloudwatch:*",
          "logs:*"
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach Policy to EC2 Role
resource "aws_iam_role_policy_attachment" "ec2_role_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}

# Create an Instance Profile for EC2 Role
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}

# Create an EC2 instance
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0" # Change to your preferred AMI
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_subnet.id
  security_groups = [aws_security_group.web_sg.name]
  key_name      = var.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y ruby-full
              sudo apt-get install -y build-essential
              sudo apt-get install -y libssl-dev
              sudo apt-get install -y zlib1g-dev
              sudo apt-get install -y libreadline-dev
              sudo apt-get install -y libyaml-dev
              sudo apt-get install -y libsqlite3-dev
              sudo apt-get install -y sqlite3
              sudo apt-get install -y libxml2-dev
              sudo apt-get install -y libxslt1-dev
              sudo apt-get install -y libcurl4-openssl-dev
              sudo apt-get install -y software-properties-common
              sudo apt-get install -y libffi-dev
              sudo apt-get install -y git
              sudo apt-get install -y postgresql postgresql-contrib
              sudo apt-get install -y nginx
              curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
              sudo apt-get install -y nodejs
              sudo gem install rails
              sudo systemctl start postgresql
              sudo systemctl enable postgresql
              sudo -u postgres psql -c "CREATE USER rails WITH PASSWORD 'password';"
              sudo -u postgres psql -c "CREATE DATABASE openstreetmap WITH OWNER rails;"
              cd /home/ubuntu
              git clone https://github.com/openstreetmap/openstreetmap-website.git
              cd openstreetmap-website
              bundle install
              rails db:migrate RAILS_ENV=production
              rails server -b 0.0.0.0 -e production
              EOF
}

# Create an RDS instance
resource "aws_db_instance" "osm_db" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "13.3"
  instance_class       = "db.t3.micro"
  #name                 = "openstreetmap"
  username             = "rails"
  password             = var.db_password
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  db_subnet_group_name = aws_db_subnet_group.main.name
  skip_final_snapshot  = true
}

# Create a DB subnet group
resource "aws_db_subnet_group" "main" {
  name       = "main"
  subnet_ids = [aws_subnet.public_subnet.id]
}

# Create an S3 bucket for static assets
resource "aws_s3_bucket" "static_assets" {
  bucket = "openstreetmap-static-assets"
  acl    = "public-read"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

# CloudWatch monitoring for EC2 instance
resource "aws_cloudwatch_log_group" "web_log_group" {
  name = "/aws/ec2/web-instance"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_stream" "web_log_stream" {
  name = "web-instance-logs"
  log_group_name = aws_cloudwatch_log_group.web_log_group.name
}
