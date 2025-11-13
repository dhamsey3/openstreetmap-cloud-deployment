variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "account_id" {
  description = "The AWS account ID"
  type        = string
}


variable "db_password" {
  description = "The database password"
  type        = string
  sensitive   = true
}

variable "db_username" {
  description = "The database username"
  type        = string
}

variable "db_name" {
  description = "The database name"
  type        = string
}

variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-central-1"
}

variable "aws_region" {
  description = "AWS region (alias for region variable)"
  type        = string
  default     = "eu-central-1"
}

variable "ecr_repo_name" {
  description = "ECR repository name for the application"
  type        = string
  default     = "openstreetmap-website"
}

variable "image_tag" {
  description = "Image tag to deploy (CI will typically set this to the git SHA)"
  type        = string
  default     = "latest"
}

