# Proxmox CSI with HashiCorp Vault Integration

This chart deploys the Proxmox CSI driver with secure credential management using HashiCorp Vault.

## Features

- **Secure Credential Management**: Proxmox API tokens stored securely in HashiCorp Vault
- **CSI Driver Integration**: Dynamic volume provisioning for Kubernetes workloads
- **Multiple Storage Classes**: Support for different storage pools (NVMe, SSD, Local, LVM)
- **Secret Sync**: Automatic synchronization of Vault secrets to Kubernetes

## Prerequisites

- Kubernetes cluster with RKE2 or similar
- HashiCorp Vault installed and configured with Kubernetes authentication
- Vault CSI provider installed in the cluster
- Proxmox VE 7.0+ with API tokens configured

## Installation

### 1. Store Proxmox Token in Vault

First, store your Proxmox API token in Vault:

```bash
# Set your Vault token and Proxmox token
export VAULT_TOKEN="your-vault-token"
export PROXMOX_TOKEN="your-proxmox-token"

# Store the token in Vault
make store-proxmox-token
```

### 2. Configure Vault Kubernetes Authentication

If you haven't already configured Vault for Kubernetes authentication:

```bash
export VAULT_TOKEN="your-vault-token"
make configure-vault
```

### 3. Deploy the Proxmox CSI Driver

Deploy the Proxmox CSI driver with Vault integration:

```bash
make install-charts
```

This will:
1. Fetch the Proxmox token from Vault
2. Create the necessary Kubernetes objects
3. Deploy the CSI driver with the secure configuration

## Architecture

The integration works as follows:

1. The Vault CSI provider mounts secrets from Vault into the CSI controller pod
2. The mounted secrets are used to authenticate with the Proxmox API
3. CSI driver uses these credentials to provision and manage volumes



## Security Considerations

- Proxmox API tokens are never stored in plaintext configuration files
- Tokens are rotated through Vault, not Kubernetes secrets directly
- Pod-only access to credentials through the Vault CSI provider