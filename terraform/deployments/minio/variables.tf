## Required variables ##

variable "proxmox_token" {
  description = "Proxmox API token (required)"
  type        = string
  sensitive   =   true
  validation {
    condition     = length(var.proxmox_token) > 0
    error_message = "The proxmox_token value cannot be empty."
  }
}

## Environment-specific overrides ##

# Only include variables where we want to override module defaults
variable "public_keys" {
  description = "SSH public keys to add to VMs"
  type        = list(string)
  default = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO3sOFB9wGEcOgNO5BfxF35Sh+EAOxWTZjx//DK4XHAx jon@blocknative.com"
  ]
}

variable "datastore" {
  description = "Proxmox datastore - specific to this deployment"
  type        = string
  default     = "ssd"
}

variable "default_gateway" {
  description = "Network default gateway - specific to this deployment"
  type        = string
  default     = "192.168.1.254"
}

variable "dns_ip" {
  description = "IP address for DNS server"
  type        = string
  default     = "192.168.1.230"
}

