variable "proxmox_endpoint" {
  description = "Proxmox API endpoint"
  type        = string
}

variable "proxmox_token" {
  description = "Proxmox API token"
  type        = string
  sensitive   = true
}

variable "node_name" {
  description = "Proxmox node name"
  type        = string
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

variable "resource_pool" {
  description = "Proxmox resource pool name"
  type        = string
}

variable "common_config" {
  description = "Common configuration for all VMs"
  type = object({
    datastore       = string
    subnet_mask     = string
    default_gateway = string
    dns_servers     = list(string)
    username        = string
    ssh_public_keys = list(string)
  })
}

variable "vm_configs" {
  description = "Map of VM configurations"
  type = map(object({
    name            = string
    cpu             = number
    memory          = number
    disk_size_gb    = number
    datastore       = optional(string)
    ip_address      = optional(string)
    subnet_mask     = optional(string)
    default_gateway = optional(string)
    dns_servers     = optional(list(string))
    username        = optional(string)
    ssh_public_keys = optional(list(string))
  }))
}

variable "generate_k8s_inventory" {
  description = "Whether to generate Kubernetes inventory file"
  type        = bool
  default     = false
}

variable "generate_runners_inventory" {
  description = "Whether to generate Runners inventory file"
  type        = bool
  default     = false
}
