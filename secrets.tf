resource "aws_secretsmanager_secret" "db_credentials" {
  name = "openstreetmap/db_credentials"
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username,
    password = var.db_password,
    dbname   = var.db_name
  })
}

output "db_credentials_arn" {
  value = aws_secretsmanager_secret.db_credentials.arn
}
