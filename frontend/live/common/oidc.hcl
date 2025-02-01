# ---------------------------------------------------------------------------------------------------------------------
# COMMON TERRAGRUNT CONFIGURATION
# This is the common component configuration for webserver-cluster. The common variables for each environment to
# deploy webserver-cluster are defined here. This configuration will be merged into the environment configuration
# via an include block.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Expose the base source URL so different versions of the module can be deployed in different environments.
  base_source_url = "git::git@github.com:nestrr/flock-infra.git//frontend/modules/oidc"
}