# k3s node running staging and production. App data lives in cloud Postgres.
resource "proxmox_virtual_environment_vm" "hermit" {
  name          = "hermit"
  node_name     = var.proxmox_node
  vm_id         = 200
  scsi_hardware = "virtio-scsi-single"

  agent {
    enabled = true
  }

  cpu {
    cores = 6
    type  = "host"
  }

  memory {
    dedicated = 6144
  }

  disk {
    datastore_id = var.vm_datastore
    interface    = "scsi0"
    size         = 80
    discard      = "on"
    iothread     = true
    ssd          = true
  }

  network_device {
    bridge      = "vmbr0"
    mac_address = "BC:24:11:81:10:7B"
  }

  operating_system {
    type = "l26"
  }

  serial_device {}

  vga {
    type = "serial0"
  }

  initialization {
    dns {
      domain  = "tailf69bc5.ts.net"
      servers = [var.gateway]
    }

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      username = "adham"
      keys     = [trimspace(file(pathexpand(var.ssh_public_key_path)))]
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

# CI runner (Forgejo Actions). Disposable: rebuilt from code, not backed up.
# Ansible installs the runner: ansible/playbooks/runner.yml
resource "proxmox_virtual_environment_vm" "echoes" {
  name          = "echoes"
  node_name     = var.proxmox_node
  vm_id         = 205
  scsi_hardware = "virtio-scsi-single"

  agent {
    enabled = true
    # The guest agent isn't in the cloud image; Ansible installs it.
    wait_for_ip {
      disabled = true
    }
  }

  cpu {
    cores = 12
    type  = "host"
  }

  memory {
    dedicated = 7168
  }

  disk {
    datastore_id = var.vm_datastore
    import_from  = proxmox_download_file.ubuntu_2404.id
    interface    = "scsi0"
    size         = 60
    discard      = "on"
    iothread     = true
    ssd          = true
  }

  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    type = "l26"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "192.168.2.15/24"
        gateway = var.gateway
      }
    }

    user_account {
      username = "adham"
      keys     = [trimspace(file(pathexpand(var.ssh_public_key_path)))]
    }
  }
}
