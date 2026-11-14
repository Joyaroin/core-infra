terraform {
  # Which Terraform version this code needs. 1.5+ gives us import blocks later.
  required_version = ">= 1.5.0"

  required_providers {
    # "proxmox" is the local name we'll use in this code.
    proxmox = {
      source  = "bpg/proxmox" # registry.terraform.io/bpg/proxmox
      version = "~> 0.122.0"  # allows 0.122.x only
    }
  }
}
