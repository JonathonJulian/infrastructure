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
    cores = lookup(each.value, "cpu", var.default_cpu)
  }

  memory {
    dedicated = lookup(each.value, "memory", var.default_memory) * 1024 # Convert GB to MB
  }

  disk {
    interface    = "scsi0"
    datastore_id = coalesce(lookup(each.value, "datastore", null), var.common_config.datastore)
    size         = lookup(each.value, "disk_size_gb", var.default_disk_size)
    file_format  = "raw"
    discard      = "on"
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  initialization {
    dns {
      servers = coalesce(lookup(each.value, "dns_servers", null), var.common_config.dns_servers)
    }

    ip_config {
      ipv4 {
        address = lookup(each.value, "ip_address", null) != null ? "${each.value.ip_address}/${coalesce(lookup(each.value, "subnet_mask", null), var.common_config.subnet_mask)}" : "dhcp"
        gateway = lookup(each.value, "ip_address", null) != null ? coalesce(lookup(each.value, "default_gateway", null), var.common_config.default_gateway) : null
      }
    }

    user_account {
      username = coalesce(lookup(each.value, "username", null), var.common_config.username, var.username)
      keys = concat(
        coalesce(lookup(each.value, "ssh_public_keys", null), []),
        var.common_config.ssh_public_keys
      )
    }
  }

  # Add a delay between VM creations
  provisioner "local-exec" {
    command = "sleep 10"
  }
}
