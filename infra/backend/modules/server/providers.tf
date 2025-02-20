provider "hcloud" {
  token = data.doppler_secrets.this.map.HCLOUD_TOKEN
}
provider "doppler" {
  doppler_token = data.aws_secretsmanager_secret_version.doppler_token.secret_string
}
