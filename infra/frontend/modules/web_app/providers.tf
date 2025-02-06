# Configure the Doppler provider with the token
provider "doppler" {
  doppler_token = data.aws_secretsmanager_secret_version.doppler_token.secret_string
}

provider "vercel" {
  api_token = data.doppler_secrets.this.map.VERCEL_API_KEY
}