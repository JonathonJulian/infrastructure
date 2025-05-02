# Infrastructure as Code - Kubernetes on Proxmox

This repository contains infrastructure automation for deploying a Kubernetes cluster on Proxmox VE using Terraform and Ansible.

## Features

- **Proxmox VM Provisioning**: Automated VM creation with customizable configurations
- **Kubernetes Deployment**: RKE2 cluster setup with control plane and worker nodes
- **Storage Integration**:
  - CSI Driver for dynamic volume provisioning
  - Multiple storage classes (NVMe, SSD, Local, LVM)
  - Volume expansion and snapshot support
- **Cloud Provider Integration**: Native Proxmox cloud provider for node management
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

### 1. Configure Proxmox API Tokens

Create API tokens in Proxmox with appropriate permissions:

```bash
# For Terraform
pveum user token add root@pam terraform --privsep=0

# For Kubernetes CSI Driver
pveum user add kubernetes-csi@pve
pveum acl modify / -user kubernetes-csi@pve -role PVEVMAdmin
pveum user token add kubernetes-csi@pve csi

# For Cloud Controller Manager
pveum user add kubernetes@pve
pveum acl modify / -user kubernetes@pve -role PVEVMAdmin
pveum user token add kubernetes@pve ccm
```

### 2. Set Environment Variables

```bash
# Set environment variables
export PROXMOX_ENDPOINT="https://your-proxmox-host:8006"
export PROXMOX_TOKEN_ENV="root@pam!terraform=your-token-uuid"
export PROXMOX_CSI_TOKEN_SECRET="your-csi-token-uuid"
export PROXMOX_CCM_TOKEN_SECRET="your-ccm-token-uuid"

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

# Test storage provisioning
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: proxmox-nvme
EOF
```

## Storage Classes

The following storage classes are available:

- **proxmox-nvme**: High-performance NVMe storage with direct sync caching
- **proxmox-ssd**: SSD-backed storage with direct sync caching
- **proxmox-local**: Local directory storage with writeback caching
- **proxmox-local-lvm**: LVM thin-provisioned storage with writeback caching

All storage classes support:
- Dynamic provisioning
- Volume expansion
- ReadWriteOnce access mode
- WaitForFirstConsumer volume binding mode

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