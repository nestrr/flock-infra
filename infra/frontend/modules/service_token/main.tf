data "aws_caller_identity" "self" {}

resource "doppler_service_token" "ci_service_token" {
  provider = doppler.personal
  project = var.project
  config  = var.config
  name    = format("Service_Token_%s-%s", var.service_token_slug, timestamp())
  access  = "read"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_kms_key" "cmk" {
  enable_key_rotation     = true
  deletion_window_in_days = 20
}

resource "aws_kms_key_policy" "cmk_admin_policy" {
  key_id = aws_kms_key.cmk.id
  policy = jsonencode({
    Id = "EnableEphemeralUserToManageCMKKey"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Get*",
          "kms:Decrypt*",
          "kms:Encrypt*"
        ]
        Resource = [aws_kms_key.cmk.arn]
        Principal = {
          "AWS": [
            format("arn:aws:iam::%s:root", data.aws_caller_identity.self.account_id),
            data.aws_caller_identity.self.arn
          ]
        }
      }
    ]
    Version = "2012-10-17"
  })
}

resource "aws_secretsmanager_secret" "doppler_service_token_secret" {
  #  count=provider::assert::expired(timeadd(existing_doppler_token.tags.created.not_after, "336h"))
  # resulting name will resemble "DOPPLER-TOKEN_provided-slug"
  name        = format("DOPPLER-ST_%s", var.service_token_slug)
  description = "Doppler Service Token"
  kms_key_id  = aws_kms_key.cmk.key_id
  tags = {
    "created" : timestamp()
  }
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [aws_kms_key_policy.cmk_admin_policy]
}

resource "aws_kms_ciphertext" "doppler_service_token_ciphertext" {
  key_id    = aws_kms_key.cmk.key_id
  plaintext = doppler_service_token.ci_service_token.key
  depends_on = [aws_kms_key_policy.cmk_admin_policy]
}

resource "aws_secretsmanager_secret_policy" "secret_management_policy" {
  secret_arn = aws_secretsmanager_secret.doppler_service_token_secret.arn
  policy     = data.aws_iam_policy_document.secret_management_policy_doc.json
}

data "aws_iam_policy_document" "secret_management_policy_doc" {
  statement {
    sid    = "EnableEphemeralUserToManageSecrets"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [
        format("arn:aws:iam::%s:root", data.aws_caller_identity.self.account_id),
        data.aws_caller_identity.self.arn
      ]
    }
    actions = [
      "secretsmanager:Create*",
      "secretsmanager:Get*",
      "secretsmanager:List*",
      "secretsmanager:Update*",
      "secretsmanager:Put*",
      "secretsmanager:Tag*",
      "secretsmanager:Untag*",
      "secretsmanager:Delete*"
    ]
    resources = [
      aws_secretsmanager_secret.doppler_service_token_secret.arn
    ]
  }
}

resource "aws_secretsmanager_secret_version" "doppler_personal_token_secret_val" {
  secret_id     = aws_secretsmanager_secret.doppler_service_token_secret.id
  secret_string = aws_kms_ciphertext.doppler_service_token_ciphertext.ciphertext_blob
  depends_on = [aws_secretsmanager_secret_policy.secret_management_policy]
}