output "doppler_service_token_secret_id" {
  value       = aws_secretsmanager_secret.doppler_service_token_secret.id
  description = "The id of the AWSSM secret ID that holds the service token value"
  sensitive   = true
}

