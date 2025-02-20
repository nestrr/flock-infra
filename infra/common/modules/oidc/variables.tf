variable "allowed_repos_branches" {
  description = "GitHub repos/branches allowed to assume the IAM role."
  type        = list(string)
  default     = ["nestrr/flock-infra"]
}
variable "enable_resource_creation" {
  description = "Whether the oidc module is allowed to create resources"
  type = bool
  default = false
}
variable "enable_oidc_provider_creation" {
  description = "Whether the oidc module is allowed to create provider"
  type = bool
  default = false
}