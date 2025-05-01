# Find the template VM by name
data "proxmox_virtual_environment_vms" "templates" {
  node_name = var.node_name
}

# Find all VMs to get the highest ID
data "proxmox_virtual_environment_vms" "all_vms" {
  node_name = var.node_name
}

# Debug outputs
output "debug_node_name" {
  value = var.node_name
}

output "debug_template_name" {
  value = var.template_name
}

output "debug_available_vms" {
  value = data.proxmox_virtual_environment_vms.templates.vms
}

output "debug_proxmox_endpoint" {
  value = var.proxmox_endpoint
}

output "debug_resource_pool" {
  value = var.resource_pool
}

output "debug_vm_configs" {
  value = var.vm_configs
}

output "debug_all_vms" {
  value = data.proxmox_virtual_environment_vms.all_vms.vms
}

locals {
  template_vm = try(
    [for vm in data.proxmox_virtual_environment_vms.templates.vms : vm if vm.name == var.template_name && vm.vm_id == 100][0],
    {
      vm_id = 100
      name  = var.template_name
    }
  )

  # VM Type Definitions
  vm_types = {
    control = {
      prefix  = "control-"
      base_id = 200
    }
    worker = {
      prefix  = "worker-"
      base_id = 300
    }
    runner = {
      prefix  = "runner-"
      base_id = 400
    }
    other = {
      prefix  = ""
      base_id = 500
    }
  }

  # Calculate VM ID based on name
  vm_id_map = {
    for name, config in var.vm_configs : name => (
      startswith(name, local.vm_types.control.prefix) ? local.vm_types.control.base_id + tonumber(substr(name, length(local.vm_types.control.prefix), -1)) :
      startswith(name, local.vm_types.worker.prefix) ? local.vm_types.worker.base_id + tonumber(substr(name, length(local.vm_types.worker.prefix), -1)) :
      startswith(name, local.vm_types.runner.prefix) ? local.vm_types.runner.base_id + tonumber(substr(name, length(local.vm_types.runner.prefix), -1)) :
      local.vm_types.other.base_id + tonumber(substr(name, length(local.vm_types.other.prefix), -1))
    )
  }
}
