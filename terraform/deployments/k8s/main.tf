terraform {
  backend "local" {
    path = "state/terraform.tfstate"
  }
}

module "k8s_cluster" {
  source = "../../modules/proxmox-vm"

  # Connection settings
  proxmox_endpoint = var.proxmox_endpoint
  proxmox_token    = var.proxmox_token
  node_name        = var.node_name
  resource_pool    = var.resource_pool
  template_name    = var.template_name

  # Enable inventory generation
  generate_k8s_inventory = true

  # Common configuration for all VMs
  common_config = {
    username        = var.username
    datastore       = var.datastore
    subnet_mask     = var.subnet_mask
    default_gateway = var.default_gateway
    dns_servers     = var.dns_servers
    ssh_public_keys = var.public_keys
  }

  # VM configurations - all VMs get defaults from the module for cpu/memory/disk
  # if not explicitly specified
  vm_configs = {
    # Control Plane Nodes - using high-resource configuration
    "control-0" = {
      name         = "control-0"
      cpu          = 16
      memory       = 32
      disk_size_gb = 200
      ip_address   = var.control_plane_ips[0]
    }
    "control-1" = {
      name         = "control-1"
      cpu          = 16
      memory       = 32
      disk_size_gb = 200
      ip_address   = var.control_plane_ips[1]
    }
    "control-2" = {
      name         = "control-2"
      cpu          = 16
      memory       = 32
      disk_size_gb = 200
      ip_address   = var.control_plane_ips[2]
    }

    # Worker Nodes - using high-resource configuration
    "worker-0" = {
      name         = "worker-0"
      cpu          = 16
      memory       = 32
      disk_size_gb = 200
      ip_address   = var.worker_ips[0]
    }
    "worker-1" = {
      name         = "worker-1"
      cpu          = 16
      memory       = 32
      disk_size_gb = 200
      ip_address   = var.worker_ips[1]
    }
    "worker-2" = {
      name         = "worker-2"
      cpu          = 16
      memory       = 32
      disk_size_gb = 200
      ip_address   = var.worker_ips[2]
    }
    "worker-3" = {
      name         = "worker-3"
      cpu          = 16
      memory       = 32
      disk_size_gb = 200
      ip_address   = var.worker_ips[3]
    }
  }
}
