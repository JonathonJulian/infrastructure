terraform {
  backend "local" {
    path = "state/terraform.tfstate"
  }
}

# Generate secure RKE2 token
resource "random_string" "rke2_token" {
  length  = 64
  special = false
  upper   = true
  lower   = true
  numeric = true
}

module "k8s_cluster" {
  source = "../../modules/proxmox-vm"
  # Only the API token is truly required, others use module defaults
  proxmox_token = var.proxmox_token

  # Override only the specific common settings that differ from module defaults
  common_config = {
    datastore       = var.datastore
    subnet_mask     = "24"
    default_gateway = var.default_gateway
    dns_servers     = ["8.8.8.8"]
    username        = "ubuntu"
    ssh_public_keys = var.public_keys
  }

  # VM configurations
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

  # Inventory generation
  inventory_enabled      = true
  inventory_template_path = "${path.module}/ansible_inventory_rke2.tmpl"
  inventory_filename     = "rke2.ini"
  inventory_extra_vars   = {
    ansible_user = "ubuntu"
    private_key  = "~/.ssh/id_ed25519"
    rke2_token   = random_string.rke2_token.result
    node_name    = "pve"  # Proxmox node name for provider_id
  }
}
