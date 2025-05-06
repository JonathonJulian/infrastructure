#!/bin/bash
set -e

# Variables
VAULT_ADDR=${VAULT_ADDR:-"https://vault.lab.local:8200"}
VAULT_TOKEN=${VAULT_TOKEN:-""}
PROXMOX_TOKEN=${PROXMOX_TOKEN:-""}
SECRET_PATH="infrastructure/proxmox/credentials"

# Check for required variables
if [ -z "$VAULT_TOKEN" ]; then
    echo "VAULT_TOKEN environment variable is required."
    echo "Example: VAULT_TOKEN='*****' ./store-proxmox-token.sh"
    exit 1
fi

if [ -z "$PROXMOX_TOKEN" ]; then
    echo "PROXMOX_TOKEN environment variable is required."
    echo "Example: PROXMOX_TOKEN='PVE:kubernetes-csi@pve!csi=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' ./store-proxmox-token.sh"
    exit 1
fi

# Configure Vault
export VAULT_ADDR=${VAULT_ADDR}
export VAULT_SKIP_VERIFY=true
export VAULT_TOKEN=${VAULT_TOKEN}

# Check if kv secrets engine is enabled
EXISTING_ENGINE=$(vault secrets list -format=json 2>/dev/null | jq -r 'has("infrastructure/")')

if [ "$EXISTING_ENGINE" != "true" ]; then
    echo "Enabling infrastructure kv secrets engine..."
    vault secrets enable -path=infrastructure kv-v2 || {
        echo "Failed to enable infrastructure secrets engine. Do you have sufficient permissions?"
        exit 1
    }
fi

# Store the Proxmox token in Vault
echo "Storing Proxmox token in Vault..."
vault kv put ${SECRET_PATH} token="${PROXMOX_TOKEN}"

echo "Proxmox token successfully stored in Vault at ${SECRET_PATH}"
echo "You can now deploy the Proxmox CSI driver with Vault integration"