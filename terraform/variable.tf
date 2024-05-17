variable "key_name" {
  description = "The name of the key pair to use for SSH access"
  type        = string
  default     = "MyKeyPair"  # Set your default key pair name here
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

