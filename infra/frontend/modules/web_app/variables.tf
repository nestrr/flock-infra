variable "token_slug" {
  description = "This is the Doppler token slug (something like frontend-stage)."
  type        = string
}
variable "production" {
  description = "Whether production or not"
  type = bool
  default = false
}