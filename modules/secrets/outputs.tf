output "secret_arn" {
  description = "ARN of the secret."
  value       = data.aws_secretsmanager_secret.secret.arn
}

output "secret_string" {
  description = "String of the secret."
  value       = data.aws_secretsmanager_secret_version.secret.secret_string
}

output "secret_json" {
  description = "JSON of the secret."
  value       = jsondecode(data.aws_secretsmanager_secret_version.secret.secret_string)
}

