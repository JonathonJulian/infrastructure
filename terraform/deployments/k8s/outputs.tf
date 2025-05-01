# Kubernetes Cluster Information
output "control_plane_nodes" {
  description = "Details of the Kubernetes control plane nodes"
  value       = module.k8s_cluster.control_plane_nodes
}

output "worker_nodes" {
  description = "Details of the Kubernetes worker nodes"
  value       = module.k8s_cluster.worker_nodes
}

output "k8s_resource_summary" {
  description = "Summary of resources allocated to the Kubernetes cluster"
  value       = module.k8s_cluster.resource_summary
}

output "k8s_network_summary" {
  description = "Network configuration summary for the Kubernetes cluster"
  value       = module.k8s_cluster.network_summary
}

# Ansible Integration
output "ansible_inventory_path" {
  description = "Path to the generated Ansible inventory file for RKE2"
  value       = "${path.root}/../../../ansible/inventory/rke2.ini"
}

# Proxmox Integration
output "proxmox_template_info" {
  description = "Information about the Proxmox template used"
  value = {
    template_id   = module.k8s_cluster.template_vm_id
    # Use the actual template name from the module output
    template_name = "ubuntu-cloud-22.04"
  }
}

# Connection Information
output "control_plane_ssh" {
  description = "SSH connection strings for the control plane nodes"
  value = {
    for name, node in module.k8s_cluster.control_plane_nodes :
    name => "ssh ubuntu@${node.ip}"
  }
}

output "worker_ssh" {
  description = "SSH connection strings for the worker nodes"
  value = {
    for name, node in module.k8s_cluster.worker_nodes :
    name => "ssh ubuntu@${node.ip}" if node.ip != "DHCP"
  }
}

# Cluster Access
output "k8s_api_endpoint" {
  description = "Kubernetes API endpoint"
  value       = "https://${module.k8s_cluster.control_plane_nodes["control-0"].ip}:6443"
}

output "kubectl_config_command" {
  description = "Command to get kubectl config after cluster is ready"
  value       = "scp ubuntu@${module.k8s_cluster.control_plane_nodes["control-0"].ip}:/etc/rancher/rke2/rke2.yaml ~/.kube/config && sed -i '' 's/127.0.0.1/${module.k8s_cluster.control_plane_nodes["control-0"].ip}/g' ~/.kube/config"
}