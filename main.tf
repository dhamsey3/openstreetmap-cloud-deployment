# Define a random string for unique bucket name suffix
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Define S3 bucket for application deployment
resource "aws_s3_bucket" "app_bucket" {
  bucket = "openstreetmap-static-assets-${random_string.bucket_suffix.result}"
  acl    = "private"

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

  lifecycle_rule {
    id      = "expire_old_versions"
    enabled = true

    expiration {
      expired_object_delete_marker = true
    }
  }
}

# Define Elastic Beanstalk Application
resource "aws_elastic_beanstalk_application" "app" {
  name        = "openstreetmap-app"
  description = "Elastic Beanstalk Application for OpenStreetMap"
}

# Define Elastic Beanstalk Application Version
resource "aws_elastic_beanstalk_application_version" "app_version" {
  name        = "v1"
  application = aws_elastic_beanstalk_application.app.name
  bucket      = aws_s3_bucket.app_bucket.bucket
  key         = "my-application.zip"
}

# Define Elastic Beanstalk Environment
resource "aws_elastic_beanstalk_environment" "env" {
  name                = "openstreetmap-env"
  application         = aws_elastic_beanstalk_application.app.name
  version_label       = aws_elastic_beanstalk_application_version.app_version.name
  solution_stack_name = "64bit Amazon Linux 2 v5.4.4 running Ruby 2.7"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_instance_profile.name
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t3.micro"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "EC2KeyName"
    value     = aws_key_pair.deployer.key_name
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.eb_role.arn
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "VPCId"
    value     = aws_vpc.main.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${aws_subnet.public_subnet_1.id},${aws_subnet.public_subnet_2.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = "${aws_subnet.public_subnet_1.id},${aws_subnet.public_subnet_2.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.main.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "DBSubnets"
    value     = "${aws_subnet.public_subnet_1.id},${aws_subnet.public_subnet_2.id}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DATABASE_URL"
    value     = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.osm_db.address}/${var.db_name}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RAILS_ENV"
    value     = "production"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = "/"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SECRET_KEY_BASE"
    value     = "your-secret-key-base"
  }
}

# Define IAM Role and Policy for Elastic Beanstalk
resource "aws_iam_role" "eb_role" {
  name = "elasticbeanstalk-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "elasticbeanstalk.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eb_role_attachment" {
  role       = aws_iam_role.eb_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

resource "aws_iam_instance_profile" "eb_instance_profile" {
  name = "elasticbeanstalk-instance-profile"
  role = aws_iam_role.eb_role.name
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Create subnets
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-west-2a"
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.4.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-west-2b"
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

# Associate the route table with the public subnets
resource "aws_route_table_association" "public_rt_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
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

# Create an RDS instance for the database
resource "aws_db_instance" "osm_db" {
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "13.15"
  instance_class         = "db.t3.micro"
  identifier             = "openstreetmapdb"
  username               = var.db_username
  password               = var.db_password
  db_name                = var.db_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  skip_final_snapshot    = true

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  depends_on = [
    aws_db_subnet_group.main,
    aws_security_group.web_sg
  ]
}

# Create a DB subnet group with a unique name
resource "aws_db_subnet_group" "main" {
  name       = "main-${random_string.bucket_suffix.result}"
  subnet_ids = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]

  tags = {
    Name = "main-${random_string.bucket_suffix.result}"
  }
}
