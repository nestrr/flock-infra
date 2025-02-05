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
  path = "${dirname(find_in_parent_folders("root.hcl"))}/frontend/live/common/oidc.hcl"
  # We want to reference the variables from the included config in this configuration, so we expose it.
  expose = true
}
# Create feature so that resource creation is only enabled if this feature is explicitly set to true.
feature "create_oidc_resources" {
  default = false
}
# Create feature so that change runs are only enabled if this feature is explicitly set to true.
feature "run_changes" {
  default = false
}
# Configure the version of the module to use in this environment. This allows you to promote new versions one
# environment at a time (e.g., qa -> stage -> prod).
terraform {
  source = "${include.common.locals.base_source_url}?ref=v0.1.0-beta.35"
  before_hook "prevent_creation" {
    commands = ["apply", "destroy", "plan"]
    execute  = feature.run_changes.value ? ["bash", "-c", "echo 'Creating resources.'"] : ["bash", "-c", "echo 'Modifying OIDC setup is skipped, as run_changes feature is set to false.' && exit 1"]
  }
}
# Exclude this unit from run queue if run-all is being used
exclude {
    if = !feature.run_changes.value
    actions = ["apply", "destroy", "plan"]
}

# ---------------------------------------------------------------------------------------------------------------------
# We don't need to override any of the common parameters for this environment, so we don't specify any inputs.
# ----------------------------------------------------------------------------------------------------------------
inputs = {
  enable_resource_creation = feature.create_oidc_resources.value
}