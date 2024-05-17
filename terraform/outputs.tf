output "ec2_instance_public_ip" {
  value = aws_instance.web.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.osm_db.endpoint
}

output "s3_bucket_name" {
  value = aws_s3_bucket.static_assets.bucket
}
