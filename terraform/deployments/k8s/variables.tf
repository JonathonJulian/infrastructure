variable "proxmox_token" {
  description = "Proxmox API token"
  type        = string
  sensitive   = true
}

variable "public_keys" {
  description = "Proxmox API endpoint"
  type        = list(string)
  default     = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO3sOFB9wGEcOgNO5BfxF35Sh+EAOxWTZjx//DK4XHAx jon@blocknative.com"
  ]
}

variable "proxmox_endpoint" {
  description = "Proxmox API endpoint"
  type        = string
  default     = "https://192.168.1.100:8006"
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

