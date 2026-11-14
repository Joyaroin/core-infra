# Downloads the official Ubuntu 24.04 cloud image onto the Proxmox host.
resource "proxmox_download_file" "ubuntu_2404" {
  node_name    = var.proxmox_node
  datastore_id = var.image_datastore
  content_type = "import"
  url          = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"

  # The file is really qcow2 despite the .img name. Proxmox decides the
  # format from the extension, so we rename it.
  file_name = "noble-server-cloudimg-amd64.qcow2"
}
