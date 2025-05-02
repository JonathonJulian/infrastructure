terraform {
  backend "local" {
    path = "state/terraform.tfstate"
  }
}

module "vault_cluster" {
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
    "vault-0" = {
      name         = "vault-0"
      cpu          = 4
      memory       = 8
      disk_size_gb = 50
      ip_address   = var.vault_ips[0]
    },
    "vault-1" = {
      name         = "vault-1"
      cpu          = 4
      memory       = 8
      disk_size_gb = 50
      ip_address   = var.vault_ips[1]
    },
    "vault-2" = {
      name         = "vault-2"
      cpu          = 4
      memory       = 8
      disk_size_gb = 50
      ip_address   = var.vault_ips[2]
    }
  }

  # Inventory generation
  inventory_enabled      = true
  inventory_template_path = "${path.module}/ansible_inventory_vault.tmpl"
  inventory_filename     = "vault.ini"
  inventory_extra_vars   = {
    ansible_user = "ubuntu"
    private_key  = "~/.ssh/id_ed25519"
  }
}
