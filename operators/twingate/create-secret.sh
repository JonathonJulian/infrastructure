#!/bin/bash
set -e

# Get Twingate API key from Vault
export VAULT_ADDR=${VAULT_ADDR:-"https://vault.lab.local:8200"}
export VAULT_SKIP_VERIFY=${VAULT_SKIP_VERIFY:-"true"}
export VAULT_TOKEN=${VAULT_TOKEN:-"******"}

echo "Retrieving Twingate API key from Vault..."
TWINGATE_API_KEY=$(vault kv get -field=api_key infrastructure/twingate)

if [ -z "$TWINGATE_API_KEY" ]; then
  echo "Error: Failed to retrieve API key from Vault"
  exit 1
fi

echo "Creating Kubernetes namespace if it doesn't exist..."
kubectl create namespace twingate-system --dry-run=client -o yaml | kubectl apply -f -

echo "Generating Kubernetes secret from Vault data..."
cat operators/twingate/twingate-secret.yaml | \
  sed "s|\${TWINGATE_API_KEY}|${TWINGATE_API_KEY}|g" | \
  kubectl apply -f -

echo "Secret created successfully!"
