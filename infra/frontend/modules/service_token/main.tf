data "aws_caller_identity" "self" {}

resource "doppler_service_token" "ci_service_token" {
  project = var.project
  config  = var.config
  name    = format("Service_Token_%s_%s_%s---%s", var.project, var.config, timestamp(), uuid())
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
        Effect   = "Allow"
        Resource = [aws_kms_key.cmk.arn]
        Action = ["kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Get*",
          "kms:Decrypt*",
        "kms:Encrypt*"]
        Principal = {
          type        = "AWS"
          identifiers = [data.aws_caller_identity.self.arn]
        }
      }
    ]
  })
}

resource "aws_secretsmanager_secret" "doppler_service_token_secret" {
  #  count=provider::assert::expired(timeadd(existing_doppler_token.tags.created.not_after, "336h"))
  # resulting name will resemble "DOPPLER-TOKEN_flock-frontend_dev"
  name        = format("DOPPLER-ST_%s_%s", var.project, var.config)
  description = "Doppler Service Token"
  kms_key_id  = aws_kms_key.cmk.key_id
  tags = {
    "created" : timestamp()
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_kms_ciphertext" "doppler_service_token_ciphertext" {
  key_id    = aws_kms_key.cmk.key_id
  plaintext = doppler_service_token.ci_service_token.key
}

data "aws_iam_policy_document" "secret_management_policy" {
  statement {
    sid    = "EnableEphemeralUserToManageSecrets"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.self.arn]
    }
    actions = [
      "secretsmanager:Create*",
      "secretsmanager:Get*",
      "secretsmanager:List*",
      "secretsmanager:Update*",
      "secretsmanager:Put*",
      "secretsmanager:Tag*",
      "secretsmanager:Untag*",
      "secretsmanager:Delete*",
    ]
    resources = [
      aws_secretsmanager_secret.doppler_service_token_secret.arn,
      aws_secretsmanager_secret_version.doppler_personal_token_secret_val.arn
    ]
  }
}

resource "aws_secretsmanager_secret_version" "doppler_personal_token_secret_val" {
  secret_id     = aws_secretsmanager_secret.doppler_service_token_secret.id
  secret_string = aws_kms_ciphertext.doppler_service_token_ciphertext.ciphertext_blob
}
