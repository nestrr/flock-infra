variable "allowed_repos_branches" {
  description = "GitHub repos/branches allowed to assume the IAM role."
  type        = list(string)
  default     = ["nestrr/flock-infra:ref:refs/heads/main"]
}
