terraform {
  backend "local" {
    path = "state/terraform.tfstate"
  }
}

module "k8s_cluster" {
  source = "../../modules/proxmox-vm"

  node_name        = var.node_name
  resource_pool    = var.resource_pool
  proxmox_endpoint = var.proxmox_endpoint
  proxmox_token    = var.proxmox_token
  username         = var.username
  template_name    = var.template_name

  generate_k8s_inventory     = true

  common_config = {
    username        = var.username
    datastore       = var.datastore
    subnet_mask     = var.subnet_mask
    default_gateway = var.default_gateway
    dns_servers     = var.dns_servers
    ssh_public_keys = var.public_keys
  }

  vm_configs = {
    # Control Plane Nodes
    "control-0" = {
      name         = "control-0"
      cpu          = 2
      memory       = 4
      disk_size_gb = 50
      ip_address   = "192.168.1.101"
    }
    "control-1" = {
      name         = "control-1"
      cpu          = 2
      memory       = 4
      disk_size_gb = 50
      ip_address   = "192.168.1.102"
    }
    "control-2" = {
      name         = "control-2"
      cpu          = 2
      memory       = 4
      disk_size_gb = 50
      ip_address   = "192.168.1.103"
    }

    # Worker Nodes
    "worker-0" = {
      name         = "worker-0"
      cpu          = 16
      memory       = 32
      disk_size_gb = 200
      ip_address   = "192.168.1.220"
    }
    "worker-1" = {
      name         = "worker-1"
      cpu          = 16
      memory       = 32
      disk_size_gb = 200
      ip_address   = "192.168.1.221"
    }
    "worker-2" = {
      name         = "worker-2"
      cpu          = 16
      memory       = 32
      disk_size_gb = 200
      ip_address   = "192.168.1.222"
    },
    "worker-3" = {
      name         = "worker-3"
      cpu          = 16
      memory       = 32
      disk_size_gb = 200
    },
    "worker-4" = {
      name         = "worker-4"
      cpu          = 16
      memory       = 32
      disk_size_gb = 200
    }
  }
}