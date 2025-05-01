# Infrastructure as Code - Kubernetes on Proxmox

This repository contains infrastructure automation for deploying a Kubernetes cluster on Proxmox VE using Terraform and Ansible.

## Features

- **Proxmox VM Provisioning**: Automated VM creation with customizable configurations
- **Kubernetes Deployment**: RKE2 cluster setup with control plane and worker nodes
- **Inventory Generation**: Automatic Ansible inventory creation for cluster configuration
- **Modular Design**: Reusable Terraform modules for different deployment scenarios

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0.0
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) >= 2.9
- Proxmox VE 7.0+ with API access
- A Proxmox template VM with:
  - Ubuntu 22.04 (cloud-init enabled)
  - qemu-guest-agent installed
  - Template VM ID 100 (or configured in variables)

## Quick Start

### 1. Configure Proxmox API Token

Create an API token in Proxmox with appropriate permissions:

```bash
pveum user token add root@pam terraform --privsep=0
```

### 2. Deploy the Kubernetes Cluster

```bash
# Set environment variables
export PROXMOX_ENDPOINT="https://your-proxmox-host:8006"
export PROXMOX_TOKEN="root@pam!terraform=your-token-uuid"

# Deploy
make deploy-k8s
```

### 3. Access Your Cluster

After deployment, the Ansible playbook automatically:
- Downloads the kubeconfig from the first control plane node
- Configures it with the correct control plane IP address
- Places it in `~/.kube/config` (with a backup of any existing config)

You can immediately use kubectl to interact with your cluster:

```bash
# Test access
kubectl get nodes
```

## Architecture

```
.
├── ansible/                # Ansible playbooks and inventory
│   ├── inventory/          # Auto-generated inventory files
│   └── rke2-cluster.yaml   # RKE2 deployment playbook
├── terraform/              # Terraform configurations
│   ├── deployments/        # Root modules for different environments
│   │   └── k8s/            # Kubernetes deployment configuration
│   └── modules/            # Reusable Terraform modules
│       └── proxmox-vm/     # Proxmox VM provisioning module
└── Makefile                # Automation commands
```

## Configuration

### Customize VM Settings

Edit `terraform/deployments/k8s/main.tf` to adjust:

- Node specifications (CPU, memory, disk)
- Network configuration
- VM naming and placement

### Advanced Settings

Additional configuration options:

- **Resource Pools**: Group VMs into Proxmox resource pools
- **Storage Options**: Configure VM storage placement
- **Network Options**: Static IP or DHCP for nodes

## Outputs

After deployment, Terraform provides useful outputs:

- SSH connection strings
- Kubernetes API endpoint
- Resource summary
- Network configuration

## Troubleshooting

Common issues:

- **API Authentication**: Ensure token has correct permissions
- **VM Provisioning**: Check Proxmox resource availability
- **Inventory Generation**: Verify Ansible inventory files in `ansible/inventory/`

## Contributing

Please follow semver conventions for versioning and create feature branches for pull requests.

## License

MIT