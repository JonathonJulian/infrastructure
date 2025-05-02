## Required variables ##

variable "proxmox_token" {
  description = "Proxmox API token (required)"
  type        = string
  sensitive   = true
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

## Deployment-specific VM addressing ##

variable "control_plane_ips" {
  description = "IP addresses for control plane nodes"
  type        = list(string)
  default     = ["192.168.1.101", "192.168.1.102", "192.168.1.103"]
}

variable "worker_ips" {
  description = "IP addresses for worker nodes with static IPs"
  type        = list(string)
  default     = ["192.168.1.220", "192.168.1.221", "192.168.1.222", "192.168.1.223", "192.168.1.224", "192.168.1.225", "192.168.1.226", "192.168.1.227", "192.168.1.228", "192.168.1.229"]
}

