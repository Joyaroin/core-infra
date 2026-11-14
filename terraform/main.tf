# A data source READS something that already exists. It never creates or changes anything.
data "proxmox_virtual_environment_nodes" "all" {}

# An output prints a value after plan/apply, and other tools (like Ansible later) can read it.
output "node_names" {
  value = data.proxmox_virtual_environment_nodes.all.names
}


