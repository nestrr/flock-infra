# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# This is the configuration for Terragrunt, a thin wrapper for Terraform and OpenTofu that helps keep your code DRY and
# maintainable: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

# Include the root `terragrunt.hcl` configuration. The root configuration contains settings that are common across all
# components and environments, such as how to configure remote state.
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Include the common configuration for the component. The common configuration contains settings that are common
# for the component across all environments.
include "common" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/frontend/live/common/service_token.hcl"
  # We want to reference the variables from the included config in this configuration, so we expose it.
  expose = true
}

# Create feature so that service token is only modified if this feature is explicitly set to true.
feature "modify_service_token" {
  default = false
}

# Configure the version of the module to use in this environment. This allows you to promote new versions one
# environment at a time (e.g., qa -> stage -> prod).
terraform {
  source = "${include.common.locals.base_source_url}?ref=v0.1.0-beta.35"
  before_hook "prevent_mod_token" {
    commands = ["apply", "destroy", "plan"]
    execute  = feature.modify_service_token.value ? ["bash", "-c", "echo 'Modifying service token.'"] : ["bash", "-c", "echo 'Modifying service token is skipped, as modify_service_token feature is set to false.' && exit 1"]
  }
}

# Exclude this unit from run queue if run-all is being used
exclude {
    if = !feature.modify_service_token.value
    actions = ["apply", "destroy", "plan"]
}

inputs = {
  project = "flock-frontend"
  config = "stage"
  service_token_slug = format("frontend-stage")
}