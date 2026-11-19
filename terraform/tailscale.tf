# The tailnet's access rules. Edit tailscale-policy.hujson here, not in the
# admin console: Terraform puts back anything changed there.
resource "tailscale_acl" "policy" {
  acl = file("${path.module}/tailscale-policy.hujson")
}

# MagicDNS answers tailnet names; everything else goes to each device's own
# DNS. (The Pi-hole on heavens-door used to be the tailnet's DNS; it's retired.)
resource "tailscale_dns_configuration" "dns" {
  magic_dns          = true
  override_local_dns = false
}
