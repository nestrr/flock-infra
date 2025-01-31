data "aws_caller_identity" "self" {}
module "oidc_github" {
  source  = "unfunco/oidc-github/aws"
  version = "1.8.1"
  github_repositories = var.allowed_repos_branches
  iam_role_inline_policies = {
      "tg_policy": data.aws_iam_policy_document.iam_policy.json
  }
}

data "aws_iam_policy_document" "iam_policy" {
  statement {
    sid = "AllowAllDynamoDBActionsOnAllTerragruntTables"
    actions = [
      "dynamodb:*"
    ]
    resources = [
      "arn:aws:dynamodb:*:*:table/terragrunt*"
    ]
  }
  statement {
    sid = "AllowAllS3ActionsOnTerragruntBuckets"
    actions = ["s3:*"]
    resources = [
        "arn:aws:s3:::terragrunt*",
        "arn:aws:s3:::terragrunt*/*"
    ]
  }
}