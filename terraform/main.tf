# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Generate an SSH key pair
resource "tls_private_key" "deployer" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create an AWS key pair using the generated public key
resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = tls_private_key.deployer.public_key_openssh
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
          "logs:*",
          "secretsmanager:GetSecretValue"
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

# Create a Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = file("~/.ssh/id_rsa.pub") # Path to your public key file
}

# Create Secrets in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name        = "db_password"
  description = "The database password"
}

resource "aws_secretsmanager_secret" "db_username" {
  name        = "db_username"
  description = "The database username"
}

resource "aws_secretsmanager_secret" "db_name" {
  name        = "db_name"
  description = "The database name"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password
}

resource "aws_secretsmanager_secret_version" "db_username" {
  secret_id     = aws_secretsmanager_secret.db_username.id
  secret_string = var.db_username
}

resource "aws_secretsmanager_secret_version" "db_name" {
  secret_id     = aws_secretsmanager_secret.db_name.id
  secret_string = var.db_name
}

# Retrieve Secrets from AWS Secrets Manager
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
}

data "aws_secretsmanager_secret_version" "db_username" {
  secret_id = aws_secretsmanager_secret.db_username.id
}

data "aws_secretsmanager_secret_version" "db_name" {
  secret_id = aws_secretsmanager_secret.db_name.id
}

# Create an EC2 instance
resource "aws_instance" "web" {
  ami                    = "ami-04ff98ccbfa41c9ad" # 
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet.id
  security_groups        = [aws_security_group.web_sg.name]
  key_name               = aws_key_pair.deployer.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name

  user_data = templatefile("user_data.sh.tpl", {
    db_username = jsondecode(data.aws_secretsmanager_secret_version.db_username.secret_string)["db_username"],
    db_password = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["db_password"],
    db_name     = jsondecode(data.aws_secretsmanager_secret_version.db_name.secret_string)["db_name"]
  })
}

# Create an RDS instance
resource "aws_db_instance" "osm_db" {
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "13.3"
  instance_class         = "db.t3.micro"
  identifier             = "openstreetmap-db" # Specify a unique identifier for the instance
  username               = jsondecode(data.aws_secretsmanager_secret_version.db_username.secret_string)["db_username"]
  password               = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["db_password"]
  db_name                = jsondecode(data.aws_secretsmanager_secret_version.db_name.secret_string)["db_name"]
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  skip_final_snapshot    = true
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
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static_assets_sse" {
  bucket = aws_s3_bucket.static_assets.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "static_assets_lifecycle" {
  bucket = aws_s3_bucket.static_assets.bucket

  rule {
    id     = "expire_old_versions"
    status = "Enabled"

    expiration {
      expired_object_delete_marker = true
    }
  }
}

# CloudWatch monitoring for EC2 instance
resource "aws_cloudwatch_log_group" "web_log_group" {
  name              = "/aws/ec2/web-instance"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_stream" "web_log_stream" {
  name           = "web-instance-logs"
  log_group_name = aws_cloudwatch_log_group.web_log_group.name
}
