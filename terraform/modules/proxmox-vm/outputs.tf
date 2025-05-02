# Template VM information
output "template_vm_id" {
  value       = local.template_vm.vm_id
  description = "The ID of the template VM used for cloning"
}

# Next available VM ID
output "next_vm_id" {
  value       = 500 # Fixed high number to avoid conflicts
  description = "The next available VM ID for new VMs"
}

# Complete VM output for all VMs
output "vms" {
  value = {
    for key, vm in proxmox_virtual_environment_vm.vm : key => {
      # Resource attributes directly from Proxmox
      id              = vm.vm_id
      name            = vm.name
      cpu_cores       = vm.cpu[0].cores
      memory          = vm.memory[0].dedicated
      disk_size_gb    = var.vm_configs[key].disk_size_gb

      # Network attributes
      network_device  = try(vm.network_device[0].bridge, null)
      mac_address     = try(vm.network_device[0].mac_address, null)

      # Values from inputs with proper fallbacks
      ip_address      = lookup(var.vm_configs[key], "ip_address", null) != null ? var.vm_configs[key].ip_address : "DHCP"
      datastore       = vm.disk[0].datastore_id

      # Role and index extraction
      role            = length(regexall("^([a-z]+)-[0-9]+", key)) > 0 ? regex("^([a-z]+)", key)[0] : "unknown"
      index           = length(regexall("-([0-9]+)$", key)) > 0 ? tonumber(regex("-([0-9]+)$", key)[0]) : 0
    }
  }
  description = "Detailed information about all VMs"
}

# Group VMs by role type
output "vm_groups" {
  value = {
    for role in distinct([
      for key, _ in var.vm_configs :
      length(regexall("^([a-z]+)-[0-9]+", key)) > 0 ? regex("^([a-z]+)", key)[0] : "unknown"
    ]) : role => {
      for key, vm in proxmox_virtual_environment_vm.vm : key => {
        id         = vm.vm_id
        name       = vm.name
        ip_address = lookup(var.vm_configs[key], "ip_address", null) != null ? var.vm_configs[key].ip_address : "DHCP"
        cpu_cores  = vm.cpu[0].cores
        memory     = vm.memory[0].dedicated
        index      = length(regexall("-([0-9]+)$", key)) > 0 ? tonumber(regex("-([0-9]+)$", key)[0]) : 0
      }
      if length(regexall("^${role}-[0-9]+", key)) > 0
    }
  }
  description = "VMs grouped by their role type extracted from name prefix"
}

# Resource Summary
output "resource_summary" {
  value = {
    total_vms = length(proxmox_virtual_environment_vm.vm)
    # Count VMs by role type
    roles = {
      for role in distinct([
        for key, _ in var.vm_configs :
        length(regexall("^([a-z]+)-[0-9]+", key)) > 0 ? regex("^([a-z]+)", key)[0] : "unknown"
      ]) : role => length([
        for key, _ in var.vm_configs : key
        if length(regexall("^${role}-[0-9]+", key)) > 0
      ])
    }
    total_cpu = sum([
      for key, vm in proxmox_virtual_environment_vm.vm : vm.cpu[0].cores
    ])
    total_memory_gb = sum([
      for key, vm in proxmox_virtual_environment_vm.vm : vm.memory[0].dedicated / 1024
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
    gateway     = var.common_config.default_gateway
    dns_servers = var.common_config.dns_servers
  }
  description = "Summary of network configuration"
}

# Inventory output
output "inventory_path" {
  value       = local.can_generate_inventory ? local.inventory_output_path : null
  description = "Path to the generated inventory file (if enabled)"
}

output "inventory_enabled" {
  value       = local.can_generate_inventory
  description = "Whether inventory generation is enabled and all prerequisites are met"
}

# Debug output to see raw values
output "raw_disk_sizes" {
  value = {
    for key, vm in proxmox_virtual_environment_vm.vm : key => {
      raw_size = try(vm.disk[0].size, "not available")
      config_size_gb = var.vm_configs[key].disk_size_gb
    }
  }
  description = "Raw disk size values from Proxmox API for debugging"
}
