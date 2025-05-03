terraform {
  backend "local" {
    path = "state/terraform.tfstate"
  }
}

module "dns_server" {
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

  # VM configurations - using a simple VM name without a type prefix
  vm_configs = {
    "dns" = {
      name         = "dns"
      cpu          = 2
      memory       = 4
      disk_size_gb = 50
      ip_address   = var.dns_ip
    }
  }

  # Inventory generation
  inventory_enabled      = true
  inventory_template_path = "${path.module}/ansible_inventory_dns.tmpl"
  inventory_filename     = "dns.ini"
  inventory_extra_vars   = {
    ansible_user = "ubuntu"
    private_key  = "~/.ssh/id_ed25519"
  }
}
