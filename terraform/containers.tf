# Pi-hole: DNS for the home network. Imported from the existing container.
resource "proxmox_virtual_environment_container" "heavens_door" {
  node_name     = var.proxmox_node
  start_on_boot = true
  unprivileged  = true

  console {
    enabled   = true
    tty_count = 2
    type      = "tty"
  }

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
        address = "192.168.2.13/24"
        gateway = var.gateway
      }
    }
  }

  network_interface {
    name        = "eth0"
    bridge      = "vmbr0"
    mac_address = "BC:24:11:95:2E:9A"
  }

  operating_system {
    # Only used when creating a container. Proxmox doesn't remember it, so an
    # imported container reports it as empty; ignore_changes below covers that.
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
