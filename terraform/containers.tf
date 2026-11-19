# Retired Pi-hole, kept stopped. Its blocklist never loaded, so it blocked
# nothing; the tailnet no longer uses it for DNS. Built from scratch;
# ansible/playbooks/pihole.yml installs everything inside.
resource "proxmox_virtual_environment_container" "heavens_door" {
  node_name     = var.proxmox_node
  vm_id         = 206
  started       = false
  start_on_boot = false
  unprivileged  = true

  memory {
    dedicated = 512
    swap      = 256
  }

  disk {
    datastore_id = var.vm_datastore
    size         = 8
  }

  features {
    nesting = true
  }

  initialization {
    hostname = "heavens-door"

    dns {
      servers = [var.gateway]
    }

    ip_config {
      ipv4 {
        address = "dhcp" # changed outside Terraform; matches the live container
      }
    }

    user_account {
      keys = [trimspace(file(pathexpand(var.ssh_public_key_path)))] # for root
    }
  }

  network_interface {
    name        = "eth0"
    bridge      = "vmbr0"
    mac_address = "BC:24:11:9C:E5:A2" # changed outside Terraform; matches the live container
  }

  operating_system {
    template_file_id = "local:vztmpl/debian-13-standard_13.6-1_amd64.tar.zst"
    type             = "debian"
  }

  lifecycle {
    # Tailscale needs /dev/net/tun, but only root@pam may pass devices through,
    # so the playbook adds it from joseph. Don't let Terraform remove it.
    ignore_changes = [device_passthrough]
  }
}

# Git server. Holds this repo, so never let Terraform delete it.
resource "proxmox_virtual_environment_container" "forgejo" {
  node_name     = var.proxmox_node
  start_on_boot = true
  unprivileged  = true

  console {
    enabled   = true
    tty_count = 2
    type      = "tty"
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 1024
    swap      = 512
  }

  disk {
    datastore_id = var.vm_datastore
    size         = 20
  }

  features {
    nesting = true
  }

  device_passthrough {
    path = "/dev/net/tun"
  }

  initialization {
    hostname = "forgejo"

    dns {
      servers = [var.gateway]
    }

    ip_config {
      ipv4 {
        address = "192.168.2.14/24"
        gateway = var.gateway
      }
    }
  }

  network_interface {
    name        = "eth0"
    bridge      = "vmbr0"
    mac_address = "BC:24:11:9B:38:80"
  }

  operating_system {
    template_file_id = "local:vztmpl/debian-13-standard_13.6-1_amd64.tar.zst"
    type             = "debian"
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      timeout_start,
      operating_system[0].template_file_id,
    ]
  }
}
