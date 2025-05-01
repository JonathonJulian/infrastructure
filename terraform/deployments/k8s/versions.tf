terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.77.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  api_token = var.proxmox_token
  insecure = true
}