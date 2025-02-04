# ---------------------------------------------------------------------------------------------------------------------
# COMMON TERRAGRUNT CONFIGURATION
# This is the common component configuration for service_token. The common variables for each environment to
# deploy service_token are defined here. This configuration will be merged into the environment configuration
# via an include block.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Expose the base source URL so different versions of the module can be deployed in different environments.
  base_source_url = "git::https://github.com/nestrr/flock-infra.git//infra/frontend/modules/service_token"
}

# Generate an Doppler provider block
generate "provider" {
  path      = "personal_doppler_token_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "doppler" {
  alias = "personal"
  doppler_token = "${get_env("DOPPLER_PT")}"
}
EOF
}