output "vault_vm_ips" {
  description = "IP addresses of Vault VMs"
  value       = [for name, vm in module.vault_cluster.vms : vm.ip_address if startswith(name, "vault-")]
}

output "ansible_inventory_vault_path" {
  description = "Path to the generated Ansible inventory file for Vault"
  value       = module.vault_cluster.inventory_path
}

output "vault_vm_details" {
  description = "Detailed information about the Vault VMs"
  value = {
    for name, vm in module.vault_cluster.vms : name => vm
    if startswith(name, "vault-")
  }
}

output "vault_ssh_commands" {
  description = "SSH commands to connect to each Vault VM"
  value = {
    for name, vm in module.vault_cluster.vms : name => "ssh ubuntu@${vm.ip_address} -i ~/.ssh/id_ed25519"
    if startswith(name, "vault-")
  }
}

output "dns_vm_ip" {
  description = "IP address of the DNS server"
  value       = module.dns_server.vms["dns"].ip_address
}

output "ansible_inventory_dns_path" {
  description = "Path to the generated Ansible inventory file for DNS"
  value       = module.dns_server.inventory_path
}

output "dns_vm_details" {
  description = "Detailed information about the DNS VM"
  value       = module.dns_server.vms["dns"]
}

output "dns_ssh_command" {
  description = "SSH command to connect to the DNS server"
  value       = "ssh ubuntu@${module.dns_server.vms["dns"].ip_address} -i ~/.ssh/id_ed25519"
}
