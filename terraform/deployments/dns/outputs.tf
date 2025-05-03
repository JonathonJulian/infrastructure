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
