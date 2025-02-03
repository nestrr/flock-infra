variable "doppler_personal_token" {
  description = "This is your Doppler personal token."
  type        = string
  sensitive   = true
  default     = ""
}
variable "doppler_service_token_secret_name" {
  description = "This is the name of the Doppler service token secret in AWS SM"
  type = string
}
variable "project" {
  description = "This is the project name in Doppler."
  type        = string
}
variable "config" {
  description = "This is the config name within the Doppler project."
  type        = string
}