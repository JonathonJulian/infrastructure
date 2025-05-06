#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
VALUES_FILE="${SCRIPT_DIR}/values.yaml"

echo -e "${YELLOW}Using values file: ${VALUES_FILE}${NC}"

# Setup Vault environment
export VAULT_ADDR=${VAULT_ADDR:-"https://vault.lab.local:8200"}
export VAULT_SKIP_VERIFY=${VAULT_SKIP_VERIFY:-"true"}

# Read network from values.yaml
NETWORK=$(grep "network:" "${VALUES_FILE}" | awk '{print $2}' | tr -d '"')

# Get API key from Vault
echo -e "${YELLOW}Retrieving Twingate API key from Vault...${NC}"

if [ -z "$VAULT_TOKEN" ]; then
  echo -e "${YELLOW}No VAULT_TOKEN found. Please enter your Vault token:${NC}"
  read -s VAULT_TOKEN
  export VAULT_TOKEN
fi

API_KEY=$(vault kv get -field=api_key infrastructure/twingate)

echo -e "${YELLOW}Fetching remote networks for Twingate network: ${NETWORK}${NC}"

# Check if we have the necessary information
if [ -z "$NETWORK" ] || [ -z "$API_KEY" ]; then
  echo -e "${RED}Missing network or API key${NC}"
  exit 1
fi

# Use Twingate GraphQL API to fetch remote networks
QUERY='{"query":"query { remoteNetworks { edges { node { id name } } } }"}'

echo -e "${YELLOW}Calling Twingate API...${NC}"

# Make the API call
RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "X-API-KEY: $API_KEY" \
  "https://${NETWORK}.twingate.com/api/graphql/" \
  -d "$QUERY")

# Check if response contains errors
if echo "$RESPONSE" | grep -q "errors"; then
  echo -e "${RED}API Error:${NC}"
  echo "$RESPONSE" | jq '.'
  exit 1
fi

# Display the remote networks
echo -e "${GREEN}Remote Networks:${NC}"
echo "$RESPONSE" | jq -r '.data.remoteNetworks.edges[] | "ID: \(.node.id)\tName: \(.node.name)"'

# Ask user to select a network ID
echo -e "\n${YELLOW}Copy the appropriate ID for your Kubernetes cluster and update the values.yaml file.${NC}"
echo -e "Set ${GREEN}remoteNetworkId${NC} to the ID value (without the quotes)."
