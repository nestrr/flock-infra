## Flock Infrastructure

This repository hosts declarative configuration for Flock infrastructure needs. We use trunk-based development with
issue tracking in Jira (issue progress is tracked automatically using Jira's integration with GitHub).

## Technologies used

See Confluence for complete reasonings behind decisions.

* Terraform for provisioning frontend and backend infrastructure.
* Terragrunt for organizing Terraform code, upholding DRY, and managing Terraform planning and application.
    * The Terragrunt GitHub Action currently fails to add comments to PRs automatically. This is being actively worked
      on: track [#19](https://github.com/gruntwork-io/terragrunt-action/issues/19).
* [Pre-commit](https://pre-commit.com/) for automatically running routine tasks on commit:
    * Creating Terraform documentation with `terraform-docs`
    * Linting with `tflint`
    * Checking vulnerabilities with `checkov` and `trivy`.
    * In the future: will run Terratest tests too, on staged files/changes.
* Ansible for configuring backend server.
    * On the frontend, Ansible is not needed as Vercel already does the setup automatically.
* [Just](https://just.systems/), a more versatile alternative to Make, for automating routine processes like token
  rotation.
* GitHub Actions, for planning and applying Terraform configurations and managing release versions.
    * Release versions allow easy tracking and specification for Terraform module configuration.

## Infrastructure Overview

See Confluence for complete reasonings behind decisions.

* We use Doppler for managing frontend and backend secrets.
* We use AWS Secrets Manager to hold the Doppler service tokens (needed by CI workers to inject backend and frontend
  secrets into their respective infrastructures.)
* We use Vercel to deploy the frontend.
    * Currently, Vercel prohibits organizations from deploying to Vercel on the Free plan. To work around this, the
      Terraform configuration currently points to a personal account's fork of the `flock-frontend` repository. To keep
      things synced, we use the Pull action is used to automatically create PRs whenever something is pushed
      to `flock-frontend/main`.
* We use Hetzner to deploy the backend.
    * In the future: we will use Docker Compose to
      pull [the latest image of the backend in GitHub Container Registry](https://github.com/nestrr/flock-backend/pkgs/container/flock-backend)
      and [Caddy](https://caddyserver.com/) to secure the server with HTTPS. See Jira and Confluence for more details.

## Development Standards

* Do not make changes to staging/prod Terraform config locally. That should only happen through CI.
*
Follow [Terragrunt's recommended folder structure](https://docs.gruntwork.io/2.0/docs/overview/concepts/infrastructure-live/).
* Do not place any secrets anywhere in the code. Secrets are managed by Doppler, so they should be placed there.
* Name your branches based on the issue they relate to (e.g. `floc-48`).
* Make concise but descriptive PRs.

## Getting Started

Thanks for helping out! To get started, clone this repository and create a Python virtual environment. Install `pip` if
needed. Then run this script:

```commandline
brew tap hashicorp/tap
brew install hashicorp/tap/terraform terraform-docs tflint trivy checkov ansible
pip install -r requirements.txt
```

You'll also need to install [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
and log in to the Nestrr AWS organization if you have not done so yet.
