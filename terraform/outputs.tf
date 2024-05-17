# outputs.tf
output "elastic_beanstalk_url" {
  value = aws_elastic_beanstalk_environment.env.endpoint_url
}
