# The tailnet's access rules. Edit tailscale-policy.hujson here, not in the
# admin console: Terraform puts back anything changed there.
resource "tailscale_acl" "policy" {
  acl = file("${path.module}/tailscale-policy.hujson")
}

# Every tailnet device asks heavens-door's Pi-hole for DNS.
resource "tailscale_dns_configuration" "dns" {
  magic_dns          = true
  override_local_dns = true

  nameservers {
    address = "100.94.141.122" # heavens-door's Tailscale IP
  }
}
