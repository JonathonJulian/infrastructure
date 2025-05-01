## API Connection ##

variable "proxmox_endpoint" {
  description = "Proxmox API endpoint"
  type        = string
  default     = "https://192.168.1.100:8006"
}

variable "proxmox_token" {
  description = "Proxmox API token"
  type        = string
  sensitive   = true
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

variable "resource_pool" {
  description = "Proxmox resource pool name"
  type        = string
  default     = "k8s"
}

## Common Configuration ##

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

  # Provide sensible defaults, but expect these to be overridden in deployments
  default = {
    datastore       = "local-lvm"
    subnet_mask     = "24"
    default_gateway = "192.168.1.1"
    dns_servers     = ["1.1.1.1", "8.8.8.8"]
    username        = "ubuntu"
    ssh_public_keys = []  # No default keys for security reasons
  }
}

## VM Definitions ##

variable "vm_configs" {
  description = "Map of VM configurations"
  type = map(object({
    name            = string
    cpu             = optional(number)
    memory          = optional(number)
    disk_size_gb    = optional(number)
    datastore       = optional(string)
    ip_address      = optional(string)
    subnet_mask     = optional(string)
    default_gateway = optional(string)
    dns_servers     = optional(list(string))
    username        = optional(string)
    ssh_public_keys = optional(list(string))
  }))

  # No default provided as VM configs are deployment-specific
}

## VM Defaults ##

variable "default_cpu" {
  description = "Default CPU cores for VMs if not specified"
  type        = number
  default     = 2
}

variable "default_memory" {
  description = "Default memory in GB for VMs if not specified"
  type        = number
  default     = 4
}

variable "default_disk_size" {
  description = "Default disk size in GB for VMs if not specified"
  type        = number
  default     = 50
}

## Feature Flags ##

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
