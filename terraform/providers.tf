# joseph. The two hosts aren't a Proxmox cluster, so each has its own API.
provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token

  # Proxmox ships with a self-signed HTTPS certificate. Without this,
  # Terraform refuses to connect. Fine on your home network.
  insecure = true
}

# jotaro: runs the CI runner (echoes). Resources here say provider = proxmox.jotaro.
provider "proxmox" {
  alias     = "jotaro"
  endpoint  = var.proxmox_jotaro_endpoint
  api_token = var.proxmox_jotaro_api_token
  insecure  = true
}

# An OAuth client from the admin console (Settings → OAuth clients) with the
# Policy File and DNS write scopes. "-" means the tailnet the client belongs to.
provider "tailscale" {
  oauth_client_id     = var.tailscale_oauth_client_id
  oauth_client_secret = var.tailscale_oauth_client_secret
  tailnet             = "-"
}
