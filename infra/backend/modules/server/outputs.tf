output "server_ipv4" {
  value = hcloud_server.backend_server.ipv4_address
}
output "server_ipv6" {
  value = hcloud_server.backend_server.ipv6_address
}