variable "doppler_personal_token" {
  description = "This is your Doppler personal token."
  type        = string
  sensitive   = true
  default     = ""
}
variable "service_token_slug" {
  description = "This is the slug of the Doppler service token, used both in AWS SM and Doppler"
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