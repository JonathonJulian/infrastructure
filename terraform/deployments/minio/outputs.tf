output "minio_vm_ip" {
  description = "IP address of the Minio server"
  value       = module.minio.vms["minio"].ip_address
}

output "ansible_inventory_minio_path" {
  description = "Path to the generated Ansible inventory file for Minio"
  value       = module.minio.inventory_path
}

output "minio_vm_details" {
  description = "Detailed information about the Minio VM"
  value       = module.minio.vms["minio"]
}

output "minio_ssh_command" {
  description = "SSH command to connect to the Minio server"
  value       = "ssh ubuntu@${module.minio.vms["minio"].ip_address} -i ~/.ssh/id_ed25519"
}
