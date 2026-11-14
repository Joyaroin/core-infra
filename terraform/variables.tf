variable "proxmox_endpoint" {
  description = "Proxmox API URL, e.g. https://192.168.1.10:8006/"
  type        = string
}

variable "proxmox_api_token" {
  description = "API token in the form user@realm!tokenname=secret"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Which Proxmox node to create things on"
  type        = string
  default     = "joseph"
}

variable "image_datastore" {
  description = "Storage for downloaded images (needs the Import content type)"
  type        = string
  default     = "local"
}

variable "vm_datastore" {
  description = "Storage for VM disks"
  type        = string
  default     = "local-lvm"
}

variable "ssh_public_key_path" {
  description = "Your public SSH key, put into VMs by cloud-init"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "gateway" {
  description = "Default gateway (your router), e.g. 192.168.1.1"
  type        = string
}
