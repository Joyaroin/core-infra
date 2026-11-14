resource "proxmox_virtual_environment_vm" "test" {
  name      = "tf-test"
  node_name = var.proxmox_node
  tags      = ["terraform", "test"]
  # No vm_id set, so Proxmox picks the next free number.

  # No guest agent in this VM, so a normal shutdown request may be ignored.
  # This makes "destroy" force it off instead of waiting forever.
  stop_on_destroy = true

  cpu {
    cores = 2
    type  = "x86-64-v2-AES" # a CPU model that works on nearly any modern host
  }

  memory {
    dedicated = 2048 # MB
  }

  disk {
    datastore_id = var.vm_datastore
    import_from  = proxmox_download_file.ubuntu_2404.id # copy the cloud image in as this disk
    interface    = "virtio0"
    iothread     = true
    discard      = "on" # lets freed space inside the VM be returned to storage
    size         = 20   # GB; grows the small cloud image to 20 GB
  }

  network_device {
    bridge = "vmbr0" # the default Proxmox network bridge
  }

  operating_system {
    type = "l26" # "Linux 2.6+ kernel", Proxmox's label for modern Linux
  }

  # Everything in here is passed to cloud-init on first boot.
  initialization {
    datastore_id = var.vm_datastore

    ip_config {
      ipv4 {
        address = var.test_vm_ip
        gateway = var.gateway
      }
    }

    user_account {
      username = "ubuntu"
      keys     = [trimspace(file(pathexpand(var.ssh_public_key_path)))]
    }
  }
}
