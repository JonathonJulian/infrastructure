# Generic inventory file generation
# This allows each deployment to provide its own template but use common generation code

locals {
  # Default template variables that should be available to all templates
  default_template_vars = {
    vms = {
      for key, vm in proxmox_virtual_environment_vm.vm : key => {
        name       = vm.name
        id         = vm.vm_id
        ip_address = lookup(var.vm_configs[key], "ip_address", null) != null ? var.vm_configs[key].ip_address : "DHCP"
        role       = length(regexall("^([a-z]+)-[0-9]+", key)) > 0 ? regex("^([a-z]+)", key)[0] : "unknown"
        index      = length(regexall("-([0-9]+)$", key)) > 0 ? tonumber(regex("-([0-9]+)$", key)[0]) : 0
      }
    }
    # Group VMs by their role type
    vm_groups = {
      for role in distinct([
        for key, _ in var.vm_configs :
        length(regexall("^([a-z]+)-[0-9]+", key)) > 0 ? regex("^([a-z]+)", key)[0] : "unknown"
      ]) : role => {
        for key, vm in proxmox_virtual_environment_vm.vm : key => {
          id         = vm.vm_id
          name       = vm.name
          ip_address = lookup(var.vm_configs[key], "ip_address", null) != null ? var.vm_configs[key].ip_address : "DHCP"
          index      = length(regexall("-([0-9]+)$", key)) > 0 ? tonumber(regex("-([0-9]+)$", key)[0]) : 0
        }
        if length(regexall("^${role}-[0-9]+", key)) > 0
      }
    }
    # Common network configuration
    network = {
      subnet_mask    = var.common_config.subnet_mask
      default_gateway = var.common_config.default_gateway
      dns_servers    = var.common_config.dns_servers
    }
  }

  # Merge default and extra variables
  template_vars = merge(local.default_template_vars, var.inventory_extra_vars)

  # Automatically constructed path when filename is provided
  constructed_path = var.inventory_filename != null ? "${path.root}/../${var.inventory_dir}/${var.inventory_filename}" : null

  # Final inventory path - explicit path has priority
  inventory_output_path = var.inventory_output_path != null ? var.inventory_output_path : local.constructed_path

  # Whether we have a valid path
  have_inventory_path = local.inventory_output_path != null

  # Check if all required components are available
  can_generate_inventory = var.inventory_enabled && var.inventory_template_path != null && local.have_inventory_path
}

resource "local_file" "inventory" {
  count    = local.can_generate_inventory ? 1 : 0
  filename = local.inventory_output_path
  content  = templatefile(var.inventory_template_path, local.template_vars)

  depends_on = [proxmox_virtual_environment_vm.vm]
}