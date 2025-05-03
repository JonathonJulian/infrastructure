#!/bin/bash
# tf-with-vault.sh
# Script to run Terraform commands with credentials from Vault

# Enable more verbose output for debugging
set -e
# Uncomment for even more verbose output: set -x

# Check if deployment directory is provided
if [ $# -lt 2 ]; then
  echo "Usage: $0 <deployment-directory> <terraform-command> [terraform-args]"
  echo "Example: $0 terraform/deployments/dns plan"
  exit 1
fi

DEPLOYMENT_DIR=$1
shift
TF_COMMAND=$1
shift
TF_ARGS=$@

# Clear any existing Vault environment variables to avoid conflicts
unset VAULT_TOKEN

# Set global Vault environment options - hardcoded for simplicity
export VAULT_SKIP_VERIFY=true
export VAULT_ADDR="https://vault.lab.local:8200"

echo "DEBUG: Using Vault server at $VAULT_ADDR with TLS verification skipped"

# Test connectivity to Vault before proceeding
if ! vault status >/dev/null 2>&1; then
  echo "ERROR: Cannot connect to Vault server at $VAULT_ADDR"
  echo "Please check your network connection and Vault server status"
  exit 1
fi

echo "DEBUG: Connected to Vault server successfully"

# If VAULT_TOKEN is not set, try to use GitHub auth
if [ -z "$VAULT_TOKEN" ]; then
  echo "Obtaining GitHub token for Vault authentication..."
  # Check if GitHub CLI is available
  if ! command -v gh &> /dev/null; then
    echo "ERROR: GitHub CLI not found. Please install it or manually set VAULT_TOKEN."
    exit 1
  fi

  # Get GitHub token
  echo "DEBUG: Running 'gh auth token' to get GitHub token"
  GH_TOKEN=$(gh auth token)
  if [ -z "$GH_TOKEN" ]; then
    echo "ERROR: Failed to get GitHub token. Please authenticate with 'gh auth login' first."
    exit 1
  fi
  echo "DEBUG: Successfully retrieved GitHub token"

  # Use GitHub token to authenticate with Vault
  echo "DEBUG: Authenticating with Vault using GitHub token"
  VAULT_TOKEN_RESULT=$(vault write -format=json auth/github/login token="$GH_TOKEN")
  if [ $? -ne 0 ]; then
    echo "ERROR: Vault authentication failed. Response from Vault:"
    echo "$VAULT_TOKEN_RESULT"
    exit 1
  fi

  export VAULT_TOKEN=$(echo "$VAULT_TOKEN_RESULT" | jq -r .auth.client_token)
  if [ -z "$VAULT_TOKEN" ] || [ "$VAULT_TOKEN" = "null" ]; then
    echo "ERROR: Failed to extract token from Vault response:"
    echo "$VAULT_TOKEN_RESULT"
    exit 1
  fi
  echo "Successfully authenticated with Vault using GitHub token"
fi

# Environment verification
echo "ENVIRONMENT CHECK:"
echo "  VAULT_ADDR=$VAULT_ADDR"
echo "  VAULT_SKIP_VERIFY=$VAULT_SKIP_VERIFY"
echo "  VAULT_TOKEN is set? $(if [ -n "$VAULT_TOKEN" ]; then echo "YES"; else echo "NO"; fi)"
echo "  Current directory: $(pwd)"

# Try to read Vault token info as a verification step
echo "DEBUG: Verifying Vault token validity"
if ! vault token lookup >/dev/null 2>&1; then
  echo "ERROR: The Vault token appears to be invalid or has insufficient permissions"
  echo "Please check your Vault token and permissions"
  exit 1
fi
echo "DEBUG: Vault token verified successfully"

# Get MinIO credentials from Vault
echo "Retrieving MinIO credentials from Vault..."
# First check if we can list the KV store to help diagnose permission issues
echo "DEBUG: Testing KV path access"
if ! vault kv list infrastructure/ >/dev/null 2>&1; then
  echo "WARNING: Cannot list Vault KV store at infrastructure/ path"
  echo "This may indicate a permissions issue, but will proceed to try direct key access"
fi

# Now try to get the actual credentials
echo "DEBUG: Retrieving MinIO credentials"
ACCESS_KEY_RESULT=$(vault kv get -format=json infrastructure/credentials/terraform 2>&1)
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to retrieve MinIO credentials from Vault:"
  echo "$ACCESS_KEY_RESULT"
  exit 1
fi

ACCESS_KEY=$(echo "$ACCESS_KEY_RESULT" | jq -r .data.data.access_key)
SECRET_KEY=$(echo "$ACCESS_KEY_RESULT" | jq -r .data.data.secret_key)

if [ -z "$ACCESS_KEY" ] || [ "$ACCESS_KEY" = "null" ] || [ -z "$SECRET_KEY" ] || [ "$SECRET_KEY" = "null" ]; then
  echo "ERROR: Failed to extract MinIO credentials from Vault response:"
  echo "$ACCESS_KEY_RESULT"
  exit 1
fi

# Set AWS environment variables for Terraform
echo "DEBUG: Setting AWS credentials environment variables"
export AWS_ACCESS_KEY_ID="$ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$SECRET_KEY"

echo "Credentials retrieved successfully."
echo "Running terraform $TF_COMMAND in $DEPLOYMENT_DIR..."
echo "----------------------------------------"

# CD to the deployment directory and run terraform
cd "$DEPLOYMENT_DIR"

# Initialize if needed (and command is not 'init')
if [ ! -d ".terraform" ] && [ "$TF_COMMAND" != "init" ]; then
  echo "Terraform not initialized. Running terraform init first..."
  terraform init
fi

# Run the specified Terraform command
terraform $TF_COMMAND $TF_ARGS

# Unset credentials after running command
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY

echo "----------------------------------------"
echo "Terraform command completed."