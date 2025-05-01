

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_token
  insecure  = true
}

# Clone from existing template for each VM
resource "proxmox_virtual_environment_vm" "vm" {
  for_each = var.vm_configs

  name      = each.value.name
  node_name = var.node_name
  vm_id     = local.vm_id_map[each.value.name]
  pool_id   = var.resource_pool

  # Add retry logic for worker errors
  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      # Ignore changes to these attributes as they are managed by Proxmox
      network_device,
    ]
  }

  clone {
    vm_id   = local.template_vm.vm_id
    retries = 3
  }

  agent {
    enabled = false
  }

  cpu {
    cores = each.value.cpu
  }

  memory {
    dedicated = each.value.memory * 1024 # Convert GB to MB
  }

  disk {
    interface    = "scsi0"
    datastore_id = coalesce(each.value.datastore, var.common_config.datastore)
    size         = each.value.disk_size_gb
    file_format  = "raw"
    discard      = "on"
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  initialization {
    dns {
      servers = coalesce(each.value.dns_servers, var.common_config.dns_servers)
    }

    ip_config {
      ipv4 {
        address = lookup(each.value, "ip_address", null) != null ? "${each.value.ip_address}/${coalesce(each.value.subnet_mask, var.common_config.subnet_mask)}" : "dhcp"
        gateway = lookup(each.value, "ip_address", null) != null ? coalesce(each.value.default_gateway, var.common_config.default_gateway) : null
      }
    }

    user_account {
      username = coalesce(each.value.username, var.common_config.username, var.username)
      keys = concat(
        coalesce(each.value.ssh_public_keys, []),
        var.common_config.ssh_public_keys
      )
    }
  }

  # Add a delay between VM creations
  provisioner "local-exec" {
    command = "sleep 10"
  }
}
