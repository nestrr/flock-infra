data "aws_caller_identity" "self" {}

module "oidc_github" {
  source              = "git::https://github.com/unfunco/terraform-aws-oidc-github.git?ref=f664e8f6002b11b5c206f1fb3cf0377ea6a033ae"
  github_repositories = var.allowed_repos_branches
  iam_role_policy_arns = [
    aws_iam_policy.iam_policy.arn
  ]
  enabled = var.enable_resource_creation
}

resource "aws_iam_policy" "iam_policy" {
  name = "oidc_policy"
  policy = data.aws_iam_policy_document.iam_policy_doc.json
}

data "aws_iam_policy_document" "iam_policy_doc" {
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
  statement {
    sid     = "AllowManageKey"
    actions = [
      "kms:Create*",
      "kms:Put*",
      "kms:Delete*",
      "kms:EnableKeyRotation",
      "kms:GenerateDataKey",
      "kms:Encrypt",
      "kms:Decrypt"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid     = "AllowManageSecret"
    actions = [
      "secretsmanager:Create*",
      "secretsmanager:Put*",
      "secretsmanager:Delete*",
      "secretsmanager:TagResource",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      format("arn:aws:secretsmanager:*:%s:secret:*", data.aws_caller_identity.self.account_id)
    ]
  }
  statement {
    sid     = "AllowCreatePolicy"
    actions = [
      "iam:CreatePolicy"
    ]
    resources = [
      format("arn:aws:secretsmanager:*:%s:secret:*", data.aws_caller_identity.self.account_id)
    ]
  }
}
