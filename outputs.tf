output "ec2_instance_public_ip" {
  value = aws_instance.web.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.osm_db.endpoint
}

output "s3_bucket_name" {
  value = aws_s3_bucket.static_assets.bucket
}
output "ec2_public_ip" {
  value = aws_instance.web.public_ip
}

# Outputs for secret ARNs
output "db_password_arn" {
  value = aws_secretsmanager_secret.db_password.arn
}

output "db_username_arn" {
  value = aws_secretsmanager_secret.db_username.arn
}

output "db_name_arn" {
  value = aws_secretsmanager_secret.db_name.arn
}
output "app_bucket_name" {
  value = aws_s3_bucket.app_bucket.bucket
}
