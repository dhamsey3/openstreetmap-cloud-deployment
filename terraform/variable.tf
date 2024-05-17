
variable "aws_region" {
  description = "The AWS region to deploy to"
  default     = "us-west-2"
}

variable "app_name" {
  description = "The name of the Elastic Beanstalk application"
  default     = "openstreetmap-app"
}

variable "env_name" {
  description = "The name of the Elastic Beanstalk environment"
  default     = "openstreetmap-env"
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "The instance type of the RDS"
  default     = "db.t3.micro"
}
