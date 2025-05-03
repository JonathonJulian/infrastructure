# Find the template VM by name
data "proxmox_virtual_environment_vms" "templates" {
  node_name = var.node_name
}

# Find all VMs to get the highest ID
data "proxmox_virtual_environment_vms" "all_vms" {
  node_name = var.node_name
}


locals {
  template_vm = try(
    [for vm in data.proxmox_virtual_environment_vms.templates.vms : vm if vm.name == var.template_name && vm.vm_id == 100][0],
    {
      vm_id = 100
      name  = var.template_name
    }
  )

  # Dictionary to map role prefixes to unique ID ranges
  # This avoids the need for complicated hashing or regex operations
  role_id_ranges = {
    "control" = 200
    "worker"  = 300
    "vault"   = 400
    "runner"  = 500
    "minio"   = 600
    "dns"     = 700
    "default" = 900
  }

  # Calculate VM ID for all VMs
  vm_id_map = {
    for name, config in var.vm_configs : name => (
      # First, check if the whole name is in role_id_ranges
      # If not, try to extract the prefix from names like "vault-2"
      # If all else fails, fall back to "default"
      (local.role_id_ranges[
        contains(keys(local.role_id_ranges), name) ? name :
        can(regex("^([a-z]+)-[0-9]+", name)) ? regex("^([a-z]+)", name)[0] :
        "default"
      ] +
       try(tonumber(regex("-([0-9]+)$", name)[0]), 0))
    )
  }
}
