terraform {
  backend "s3" {
    bucket = "terraform-state"           # Name of the S3 bucket
    key    = "haproxy/terraform.tfstate"     # Name of the tfstate file

    endpoints = {
      s3 = "https://minio.lab.local:9091"    # MinIO endpoint (using HTTPS)
    }

    # Credentials will be provided by environment variables set by the tf-with-vault.sh script:
    # AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
    access_key = "minioadmin"
    secret_key = "supersecret"

    region                      = "us-west-1"   # Region will be ignored
    skip_credentials_validation = true    # Skip AWS related checks and validations
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style              = true    # Enable path-style S3 URLs
    insecure                    = true    # Skip TLS certificate verification
  }
}

module "haproxy_server" {
  source = "../../modules/proxmox-vm"
  # Only the API token is truly required, others use module defaults
  proxmox_token = var.proxmox_token
  proxmox_endpoint = "https://pve.lab.local:8006"

  # Override only the specific common settings that differ from module defaults
  common_config = {
    datastore       = var.datastore
    subnet_mask     = "24"
    default_gateway = var.default_gateway
    dns_servers     = ["192.168.1.240"]
    username        = "ubuntu"
    ssh_public_keys = var.public_keys
  }

  # VM configurations - using a simple VM name without a type prefix
  vm_configs = {
    "haproxy" = {
      name         = "haproxy"
      cpu          = 2
      memory       = 4
      disk_size_gb = 50
      ip_address   = var.ip
    }
  }

  # Inventory generation
  inventory_enabled      = true
  inventory_template_path = "${path.module}/inventory.tmpl"
  inventory_filename     = "haproxy.ini"
  inventory_extra_vars   = {
    ansible_user = "ubuntu"
    private_key  = "~/.ssh/id_ed25519"
  }
}
