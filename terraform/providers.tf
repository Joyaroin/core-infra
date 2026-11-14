provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token

  # Proxmox ships with a self-signed HTTPS certificate. Without this,
  # Terraform refuses to connect. Fine on your home network.
  insecure = true
}
