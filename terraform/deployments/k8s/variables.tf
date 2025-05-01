variable "proxmox_token" {
  description = "Proxmox API token"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.proxmox_token) > 0
    error_message = "The proxmox_token value cannot be empty."
  }
}

variable "public_keys" {
  description = "SSH public keys to add to VMs"
  type        = list(string)
  default = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO3sOFB9wGEcOgNO5BfxF35Sh+EAOxWTZjx//DK4XHAx jon@blocknative.com"
  ]
}

variable "proxmox_endpoint" {
  description = "Proxmox API endpoint"
  type        = string
  default     = "https://192.168.1.100:8006"
  validation {
    condition     = length(var.proxmox_endpoint) > 0
    error_message = "The proxmox_endpoint value cannot be empty."
  }
}

variable "resource_pool" {
  description = "Proxmox resource pool"
  type        = string
  default     = "k8s"
}
variable "node_name" {
  description = "Proxmox node name"
  type        = string
  default     = "pve"
}

variable "template_name" {
  description = "The name of the template VM to clone from"
  type        = string
  default     = "ubuntu-cloud-22.04"
}

variable "username" {
  description = "Default username for SSH access"
  type        = string
  default     = "ubuntu"
}

variable "datastore" {
  description = "Proxmox datastore"
  type        = string
  default     = "ssd"
}

variable "subnet_mask" {
  description = "Subnet mask"
  type        = string
  default     = "24"
}

variable "default_gateway" {
  description = "Default gateway"
  type        = string
  default     = "192.168.1.254"
}

variable "dns_servers" {
  description = "DNS servers"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "control_plane_ips" {
  description = "IP addresses for control plane nodes"
  type        = list(string)
  default     = ["192.168.1.101", "192.168.1.102", "192.168.1.103"]
}

variable "worker_ips" {
  description = "IP addresses for worker nodes with static IPs"
  type        = list(string)
  default     = ["192.168.1.220", "192.168.1.221", "192.168.1.222", "192.168.1.223", "192.168.1.224"]
}

