variable "key_name" {
  description = "The name of the key pair to use for SSH access"
  type        = string
}

variable "region" {
  description = "The AWS region"
  type        = string
  default     = "us-west-2"
}

variable "account_id" {
  description = "The AWS account ID"
  type        = string
}
