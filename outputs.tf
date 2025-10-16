output "rds_endpoint" {
  value = aws_db_instance.osm_db.endpoint
}

output "app_bucket_name" {
  value = aws_s3_bucket.app_bucket.bucket
}
