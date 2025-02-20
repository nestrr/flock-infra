# This module can only be run once, and it has already been run. So, it is excluded from all future runs.
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_oidc_github"></a> [oidc\_github](#module\_oidc\_github) | git::https://github.com/unfunco/terraform-aws-oidc-github.git | f664e8f6002b11b5c206f1fb3cf0377ea6a033ae |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy_document.iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_repos_branches"></a> [allowed\_repos\_branches](#input\_allowed\_repos\_branches) | GitHub repos/branches allowed to assume the IAM role. | `list(string)` | <pre>[<br/>  "nestrr/flock-infra:ref:refs/heads/main"<br/>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | ARN of created IAM role |
<!-- END_TF_DOCS -->