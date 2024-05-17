variable "db_password" {
  description = "The password for the RDS instance"
  type        = string
  sensitive   = true
}

variable "key_name" {
  description = "The name of the key pair to use for SSH access"
  type        = string
}
