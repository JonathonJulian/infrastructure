# Generate secure RKE2 token
resource "random_string" "rke2_token" {
  count   = var.generate_k8s_inventory ? 1 : 0
  length  = 64
  special = false
  upper   = true
  lower   = true
  numeric = true
}

# Generate Kubernetes Ansible inventory file
resource "local_file" "ansible_inventory" {
  count    = var.generate_k8s_inventory ? 1 : 0
  filename = "${path.root}/../../../ansible/inventory/rke2.ini"
  content = templatefile("${path.module}/templates/rke2.tpl", {
    masters = {
      for key, config in var.vm_configs : key => config
      if startswith(key, "control-")
    }
    workers = {
      for key, config in var.vm_configs : key => config
      if startswith(key, "worker-")
    }
    rke2_token = random_string.rke2_token[0].result
  })
  depends_on = [proxmox_virtual_environment_vm.vm]
}

# Generate Runners inventory file
resource "local_file" "runners_inventory" {
  count    = var.generate_runners_inventory ? 1 : 0
  filename = "${path.root}/../../../ansible/inventory/runners.ini"
  content = templatefile("${path.module}/templates/runners.tpl", {
    runners = {
      for key, config in var.vm_configs : key => config
      if startswith(key, "runner-")
    }
  })
  depends_on = [proxmox_virtual_environment_vm.vm]
}
