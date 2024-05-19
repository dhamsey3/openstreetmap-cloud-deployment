# Terraform provider configuration with default tags
provider "aws" {
  region = "us-west-2" 
  
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
