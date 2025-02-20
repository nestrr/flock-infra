data "aws_secretsmanager_secret_version" "doppler_token" {
  # Refer to infra/frontend/live/common/service_token.hcl's service_token_slug input
  secret_id = format("DOPPLER-ST_%s", var.token_slug)
}
data "doppler_secrets" "this" {}

resource "hcloud_ssh_key" "main" {
  name       = "main_ssh_key"
  public_key = var.public_key
}
resource "hcloud_server" "backend_server" {
  name        = "node1"
  image       = "fedora-41"
  server_type = "cpx11"
  location    = "hil"
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  ssh_keys = [hcloud_ssh_key.main.id]
}