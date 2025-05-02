# Kubernetes Cluster Information
output "control_plane_nodes" {
  description = "Details of the Kubernetes control plane nodes"
  value = {
    for name, vm in module.k8s_cluster.vms : name => vm
    if startswith(name, "control-")
  }
}

output "worker_nodes" {
  description = "Details of the Kubernetes worker nodes"
  value = {
    for name, vm in module.k8s_cluster.vms : name => vm
    if startswith(name, "worker-")
  }
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
  description = "Path to the generated Ansible inventory file for Kubernetes"
  value       = module.k8s_cluster.inventory_path
}

# Proxmox Integration
output "proxmox_template_info" {
  description = "Information about the Proxmox template used"
  value = {
    template_id = module.k8s_cluster.template_vm_id
    # Use the actual template name from the module output
    template_name = "ubuntu-cloud-22.04"
  }
}

# Connection Information
output "control_plane_ssh" {
  description = "SSH connection strings for the control plane nodes"
  value = {
    for name, vm in module.k8s_cluster.vms : name => "ssh ubuntu@${vm.ip_address}"
    if startswith(name, "control-")
  }
}

output "worker_ssh" {
  description = "SSH connection strings for the worker nodes"
  value = {
    for name, vm in module.k8s_cluster.vms : name => "ssh ubuntu@${vm.ip_address}"
    if startswith(name, "worker-") && vm.ip_address != "DHCP"
  }
}

# Cluster Access
output "k8s_api_endpoint" {
  description = "Kubernetes API endpoint"
  value       = "https://${module.k8s_cluster.vms["control-0"].ip_address}:6443"
}

output "kubectl_config_command" {
  description = "Command to get kubectl config after cluster is ready"
  value       = "scp ubuntu@${module.k8s_cluster.vms["control-0"].ip_address}:/etc/rancher/rke2/rke2.yaml ~/.kube/config && sed -i '' 's/127.0.0.1/${module.k8s_cluster.vms["control-0"].ip_address}/g' ~/.kube/config"
}

output "control_plane_ips" {
  description = "IP addresses of Kubernetes control plane nodes"
  value       = [for name, vm in module.k8s_cluster.vms : vm.ip_address if startswith(name, "control-")]
}

output "worker_ips" {
  description = "IP addresses of Kubernetes worker nodes"
  value       = [for name, vm in module.k8s_cluster.vms : vm.ip_address if startswith(name, "worker-")]
}

output "rke2_token" {
  description = "RKE2 token for node registration"
  value       = random_string.rke2_token.result
  sensitive   = true
}
