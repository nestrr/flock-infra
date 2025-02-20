# ---------------------------------------------------------------------------------------------------------------------
# COMMON TERRAGRUNT CONFIGURATION
# This is the common component configuration for service_token. The common variables for each environment to
# deploy service_token are defined here. This configuration will be merged into the environment configuration
# via an include block.
# ---------------------------------------------------------------------------------------------------------------------


locals {
  # Expose the base source URL so different versions of the module can be deployed in different environments.
  base_source_url = "git::https://github.com/nestrr/flock-infra.git//infra/backend/modules/server"

  # Read environment (same as config name - dev/prod/stage), project (Doppler project name), and layer (project name, excluding extra information - frontend/backend)
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  global_vars      = read_terragrunt_config(find_in_parent_folders("globals.hcl"))
  environment      = local.environment_vars.locals.environment
  project          = local.global_vars.locals.project_name
  layer_arr        = split("-", local.project)
  layer            = element(local.layer_arr, length(local.layer_arr)-1)
}

inputs = {
  token_slug = "${local.layer}-${local.environment}"
}