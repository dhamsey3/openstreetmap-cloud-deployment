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

