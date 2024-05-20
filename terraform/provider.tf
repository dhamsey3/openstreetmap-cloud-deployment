# Terraform provider configuration with default tags
provider "aws" {
  region = "eu-central-1" 
  
  default_tags {
    tags = {
      Environment = "production"
      Project     = "openstreetmap-website"
      Owner       = "dhamsey3"
      Department  = "IT"
      CostCenter  = "12345"
    }
  }
}


terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0.0"
    }
  }
}
