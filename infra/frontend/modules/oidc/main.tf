data "aws_caller_identity" "self" {}

module "oidc_github" {
  source              = "git::https://github.com/unfunco/terraform-aws-oidc-github.git?ref=f664e8f6002b11b5c206f1fb3cf0377ea6a033ae"
  github_repositories = var.allowed_repos_branches
  iam_role_inline_policies = {
    "tg_policy" : data.aws_iam_policy_document.iam_policy.json
  }
  enabled = var.enable_resource_creation
  create_oidc_provider = var.enable_oidc_provider_creation
}

data "aws_iam_policy_document" "iam_policy" {
  statement {
    sid = "AllowAllDynamoDBActionsOnAllTerragruntTables"
    actions = [
      "dynamodb:*"
    ]
    resources = [
      "arn:aws:dynamodb:*:*:table/tf-locks*"
    ]
  }
  statement {
    sid     = "AllowAllS3ActionsOnTerragruntBuckets"
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::terragrunt*",
      "arn:aws:s3:::terragrunt*/*"
    ]
  }
}