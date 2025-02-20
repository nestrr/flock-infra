output "iam_role_arn" {
  value       = module.oidc_github.iam_role_arn
  description = "ARN of created IAM role"
  sensitive   = true
}