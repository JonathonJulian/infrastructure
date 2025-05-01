# Template VM information
output "template_vm_id" {
  value       = local.template_vm.vm_id
  description = "The ID of the template VM used for cloning"
}

# Next available VM ID
output "next_vm_id" {
  value       = 500  # Fixed high number to avoid conflicts
  description = "The next available VM ID for new VMs"
}

# Control Plane Nodes Information
output "control_plane_nodes" {
  value = {
    for key, vm in proxmox_virtual_environment_vm.vm : key => {
      name        = vm.name
      id          = vm.vm_id
      ip          = lookup(var.vm_configs[key], "ip_address", null) != null ? var.vm_configs[key].ip_address : "DHCP"
      cpu         = var.vm_configs[key].cpu
      memory_gb   = var.vm_configs[key].memory
      disk_gb     = var.vm_configs[key].disk_size_gb
      datastore   = var.vm_configs[key].datastore
      network     = lookup(var.vm_configs[key], "ip_address", null) != null ? "static" : "dhcp"
      ssh_keys    = concat(
        coalesce(var.vm_configs[key].ssh_public_keys, []),
        var.common_config.ssh_public_keys
      )
    }
    if startswith(key, "control-")
  }
  description = "Detailed information about all control plane nodes"
}

# Worker Nodes Information
output "worker_nodes" {
  value = {
    for key, vm in proxmox_virtual_environment_vm.vm : key => {
      name        = vm.name
      id          = vm.vm_id
      ip          = lookup(var.vm_configs[key], "ip_address", null) != null ? var.vm_configs[key].ip_address : "DHCP"
      cpu         = var.vm_configs[key].cpu
      memory_gb   = var.vm_configs[key].memory
      disk_gb     = var.vm_configs[key].disk_size_gb
      datastore   = var.vm_configs[key].datastore
      network     = lookup(var.vm_configs[key], "ip_address", null) != null ? "static" : "dhcp"
      ssh_keys    = concat(
        coalesce(var.vm_configs[key].ssh_public_keys, []),
        var.common_config.ssh_public_keys
      )
    }
    if startswith(key, "worker-")
  }
  description = "Detailed information about all worker nodes"
}

# All VMs Summary
output "all_vms" {
  value = {
    for key, vm in proxmox_virtual_environment_vm.vm : key => {
      name        = vm.name
      id          = vm.vm_id
      ip          = lookup(var.vm_configs[key], "ip_address", null) != null ? var.vm_configs[key].ip_address : "DHCP"
      cpu         = var.vm_configs[key].cpu
      memory_gb   = var.vm_configs[key].memory
      disk_gb     = var.vm_configs[key].disk_size_gb
      datastore   = var.vm_configs[key].datastore
      network     = lookup(var.vm_configs[key], "ip_address", null) != null ? "static" : "dhcp"
      ssh_keys    = concat(
        coalesce(var.vm_configs[key].ssh_public_keys, []),
        var.common_config.ssh_public_keys
      )
    }
  }
  description = "Detailed information about all VMs"
}

# Resource Summary
output "resource_summary" {
  value = {
    total_vms = length(proxmox_virtual_environment_vm.vm)
    control_planes = length({
      for key, vm in proxmox_virtual_environment_vm.vm : key => vm
      if startswith(key, "control-")
    })
    workers = length({
      for key, vm in proxmox_virtual_environment_vm.vm : key => vm
      if startswith(key, "worker-")
    })
    total_cpu = sum([
      for key, config in var.vm_configs : config.cpu
    ])
    total_memory_gb = sum([
      for key, config in var.vm_configs : config.memory
    ])
    total_disk_gb = sum([
      for key, config in var.vm_configs : config.disk_size_gb
    ])
  }
  description = "Summary of all resources allocated"
}

# Network Summary
output "network_summary" {
  value = {
    static_ips = {
      for key, config in var.vm_configs : key => config.ip_address
      if lookup(config, "ip_address", null) != null
    }
    dhcp_ips = {
      for key, config in var.vm_configs : key => "DHCP"
      if lookup(config, "ip_address", null) == null
    }
    subnet_mask = var.common_config.subnet_mask
    gateway = var.common_config.default_gateway
    dns_servers = var.common_config.dns_servers
  }
  description = "Summary of network configuration"
}