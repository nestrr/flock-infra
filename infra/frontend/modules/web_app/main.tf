data "aws_secretsmanager_secret_version" "doppler_token" {
  # Refer to infra/frontend/live/common/service_token.hcl's service_token_slug input
  secret_id = format("DOPPLER-ST_%s", var.token_slug)
}
data "doppler_secrets" "this" {}
# data.doppler_secrets.this.map
resource "vercel_project" "vercel_app" {
  name           = "flock-frontend-prod"
  framework      = "nextjs"
  git_repository = {
    type = "github"
    # TODO: change to Nestrr-owned repo when ready to deploy. This also requires changing the Vercel API key in Doppler.
    repo = "maryam-khan-dev/flock-frontend"
  }
  serverless_function_region = "pdx1"
}

resource "vercel_attack_challenge_mode" "example" {
  project_id = vercel_project.vercel_app.id
  # Enabled only when NOT in production, as we don't want to show Captcha to each visitor when live!
  enabled    = var.production != true ? false : true
}
resource "vercel_project_domain" "example" {
  project_id = vercel_project.vercel_app.id
  domain     = "nestrr.io"
}
# A redirect of a domain name to a second domain name.
# The status_code can optionally be controlled.
resource "vercel_project_domain" "example_redirect" {
  project_id           = vercel_project.vercel_app.id
  domain               = "www.nestrr.io"
  redirect             = vercel_project_domain.example.domain
  redirect_status_code = 307
}

resource "vercel_project_environment_variables" "vercel_app_envs" {
  project_id = vercel_project.vercel_app.id
  variables  = [
    for secret_name, secret_value in data.doppler_secrets.this.map :
    {
      key       = secret_name,
      value     = secret_value,
      target    = [var.production == true ? "production" : "preview"]
      sensitive = true
    }
  ]
}

