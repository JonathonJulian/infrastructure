output "haproxy_vm_ip" {
  description = "IP address of the HAProxy server"
  value       = module.haproxy_server.vms["haproxy"].ip_address
}

output "ansible_inventory_haproxy_path" {
  description = "Path to the generated Ansible inventory file for HAProxy"
  value       = module.haproxy_server.inventory_path
}

output "haproxy_vm_details" {
  description = "Detailed information about the HAProxy VM"
  value       = module.haproxy_server.vms["haproxy"]
}

output "haproxy_ssh_command" {
  description = "SSH command to connect to the HAProxy server"
  value       = "ssh ubuntu@${module.haproxy_server.vms["haproxy"].ip_address} -i ~/.ssh/id_ed25519"
}
