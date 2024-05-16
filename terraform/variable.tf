
variable "aws_region" {
  description = "The AWS region to deploy to"
  default     = "us-west-2"
}

variable "db_username" {
  description = "Database username"
}

variable "db_password" {
  description = "Database password"
  sensitive   = true
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.medium"
}
